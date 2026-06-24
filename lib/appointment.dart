// appointments_screen.dart
import 'package:clinic_portal/admitted.dart';
import 'package:clinic_portal/dr%20dash/invoice_screen.dart';

import 'package:clinic_portal/patient.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? _selectedDoctorSpeciality;
  String? _selectedDoctorPhone;
  List<String> _generateTimeSlots(
    String start,
    String end,
    int durationMinutes,
  ) {
    // start, end format: "10:00 AM"
    final format = DateFormat.jm();
    DateTime startTime = format.parse(start);
    DateTime endTime = format.parse(end);

    List<String> slots = [];
    while (startTime.isBefore(endTime)) {
      slots.add(format.format(startTime));
      startTime = startTime.add(Duration(minutes: durationMinutes));
    }
    return slots;
  }

  // Open Patient History

  String? _selectedAppointmentType;

  // Form & state variables
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _patientName;
  String? _phone;
  String? _gender;
  String? _age;
  String? _cnic;
  String? _doctorFee;
  String? _selectedDoctorName;
  String? _selectedDoctorUid;
  String? _selectedDuration;
  String? _selectedTimeSlot;
  DateTime? _selectedDate;

  Stream<QuerySnapshot> get _doctorsStream =>
      FirebaseFirestore.instance.collection('doctors').snapshots();

  // Format Date
  String _formatDateForFirestore(DateTime d) => "${d.day}-${d.month}-${d.year}";

  // Create Appointment
  Future<void> _createAppointment() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")),
        );
      }
      return;
    }

    form.save();

    if (_patientName == null ||
        _phone == null ||
        _gender == null ||
        _age == null ||
        _cnic == null ||
        _selectedDoctorName == null ||
        _selectedDoctorUid == null ||
        _selectedDuration == null ||
        _selectedTimeSlot == null ||
        _selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")),
        );
      }
      return;
    }

    final Map<String, dynamic> data = {
      'patient': _patientName,
      'phone': _phone,
      'gender': _gender,
      'age': _age,
      'cnic': _cnic,

      'doctor': _selectedDoctorName,
      'doctorUid': _selectedDoctorUid?.trim(),
      'appointmentType': _selectedAppointmentType,
      'duration': _selectedDuration,
      'time': _selectedTimeSlot,
      'date': _formatDateForFirestore(_selectedDate!),
      'status': 'Pending',
      'fee': _doctorFee, //
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('appointments').add(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating appointment: $e')),
        );
      }
    }
  }

  // Show create appointment dialog
  void _showCreateAppointmentDialog() {
    _patientName = null;
    _phone = null;
    _gender = null;
    _age = null;
    _cnic = null;
    _selectedDoctorName = null;
    _selectedDoctorUid = null;
    _selectedDuration = null;
    _selectedTimeSlot = null;
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController dateController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Create Appointment"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Patient Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Patient Name",
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? "Enter patient name"
                                : null,
                    onSaved: (v) => _patientName = v?.trim(),
                  ),
                  const SizedBox(height: 12),

                  // Gender
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Gender"),
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    validator: (v) => v == null ? "Select gender" : null,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),

                  // Age
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? "Enter age" : null,
                    onSaved: (v) => _age = v?.trim(),
                  ),
                  const SizedBox(height: 12),

                  // CNIC
                  TextFormField(
                    decoration: const InputDecoration(labelText: "CNIC"),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? "Enter CNIC" : null,
                    onSaved: (v) => _cnic = v?.trim(),
                  ),
                  const SizedBox(height: 12),

                  // Phone Number
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter phone number";
                      if (!RegExp(r'^\d{10,15}$').hasMatch(v))
                        return "Enter valid phone number";
                      return null;
                    },
                    onSaved: (v) => _phone = v?.trim(),
                  ),

                  const SizedBox(height: 12),

                  // Appointment Type
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Appointment Type",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Physical",
                        child: Text("Physical Appointment"),
                      ),
                      DropdownMenuItem(
                        value: "Online",
                        child: Text("Online Video Consultation"),
                      ),
                    ],
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? "Select appointment type"
                                : null,
                    onChanged:
                        (v) => setState(() => _selectedAppointmentType = v),
                  ),
                  const SizedBox(height: 12),

                  // Doctor dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: _doctorsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      final items =
                          docs.map((d) {
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Text(d['name'] ?? ''),
                            );
                          }).toList();

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Doctor",
                        ),
                        items: items,
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? "Select doctor" : null,
                        onChanged: (v) {
                          setState(() {
                            _selectedDoctorUid = v; // UID
                            final docData =
                                docs.firstWhere((d) => d.id == v).data()
                                    as Map<String, dynamic>;
                            _selectedDoctorName = docData['name'];
                            _doctorFee = docData['fee'];
                            _selectedDoctorSpeciality = docData['speciality'];
                            _selectedDoctorPhone = docData['phone'];
                          });
                        },
                      );
                    },
                  ),
                  if (_selectedDoctorUid != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Speciality: $_selectedDoctorSpeciality"),
                          Text("Phone: $_selectedDoctorPhone"),
                        ],
                      ),
                    ),

                  // Show doctor fee dynamically
                  if (_doctorFee != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        initialValue: _doctorFee,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Consultation Fee",
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Date picker
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Select Date"),
                    validator:
                        (_) => _selectedDate == null ? "Select date" : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        dateController.text = _formatDateForFirestore(date);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Duration
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Duration",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "15 min",
                        child: Text("15 minutes"),
                      ),
                      DropdownMenuItem(
                        value: "30 min",
                        child: Text("30 minutes"),
                      ),
                      DropdownMenuItem(
                        value: "45 min",
                        child: Text("45 minutes"),
                      ),
                      DropdownMenuItem(value: "1 hour", child: Text("1 hour")),
                    ],
                    validator: (v) => v == null ? "Select duration" : null,
                    onChanged: (v) => setState(() => _selectedDuration = v),
                  ),
                  const SizedBox(height: 12),

                  // Time Slot
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Time Slot",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "10:00 AM",
                        child: Text("10:00 AM"),
                      ),
                      DropdownMenuItem(
                        value: "11:00 AM",
                        child: Text("11:00 AM"),
                      ),
                      DropdownMenuItem(
                        value: "12:00 PM",
                        child: Text("12:00 PM"),
                      ),
                      DropdownMenuItem(
                        value: "02:00 PM",
                        child: Text("02:00 PM"),
                      ),
                      DropdownMenuItem(
                        value: "04:00 PM",
                        child: Text("04:00 PM"),
                      ),
                    ],
                    validator: (v) => v == null ? "Select time slot" : null,
                    onChanged: (v) => setState(() => _selectedTimeSlot = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _createAppointment,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Update Status
  Future<void> _updateStatus(DocumentReference docRef, String newStatus) async {
    try {
      final docSnap = await docRef.get();
      final data = docSnap.data() as Map<String, dynamic>?;

      if (data == null) return;

      await docRef.update({'status': newStatus});

      if (newStatus == 'Admitted') {
        final admittedData = {
          'mrNumber':
              data['mr'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'name': data['patient'] ?? '',
          'phone': data['phone'] ?? '',
          'gender': data['gender'] ?? '',
          'age': data['age'] ?? '',
          'cnic': data['cnic'] ?? '',
          'doctor': data['doctor'] ?? '',
          'visitTime': data['time'] ?? '',
          'admitDate': Timestamp.now(),
          'status': 'Admitted',
          'createdAt': Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection('admittedPatients')
            .add(admittedData);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdmittedPatientsScreen()),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to "$newStatus"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  // Open Patient History
  // Open Patient History
  void _openHistory(
    String patientName,
    String phone,
    String mrNumber,
    String doctorUid,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PatientHistoryScreen(
              patientName: patientName,
              phone: phone,
              mrNumber: mrNumber,
              doctorUid: doctorUid, // <- Pass doctorUid here
            ),
      ),
    );
  }

  void _openInvoice(String appointmentId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => InvoiceScreen(
              appointmentId: appointmentId,
              appointmentData: data,
            ),
      ),
    );
  }

  void _openPrescription(String appointmentId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => InvoiceScreen(
              appointmentId: appointmentId,
              appointmentData: data,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Appointments",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showCreateAppointmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Create Appointment"),
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('appointments')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final appointments = snapshot.data!.docs;
                    if (appointments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("No appointments found."),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text("Patient")),
                          DataColumn(label: Text("Gender")),
                          DataColumn(label: Text("Age")),
                          DataColumn(label: Text("CNIC")),

                          DataColumn(label: Text("Doctor")),
                          DataColumn(label: Text("Fee")),

                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Time")),
                          DataColumn(label: Text("Duration")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows:
                            appointments.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final patient = data['patient'] ?? '';
                              final gender = data['gender'] ?? '';
                              final age = data['age'] ?? '';
                              final cnic = data['cnic'] ?? '';
                              final doctor = data['doctor'] ?? '';
                              final fee = data['fee'] ?? '';
                              final date = data['date'] ?? '';
                              final time = data['time'] ?? '';
                              final duration = data['duration'] ?? '';
                              final status = data['status'] ?? 'Pending';
                              final phone = data['phone'] ?? '';
                              final mrNumber = data['mr'] ?? '';

                              return DataRow(
                                cells: [
                                  DataCell(Text(patient)),
                                  DataCell(Text(gender)),
                                  DataCell(Text(age)),
                                  DataCell(Text(cnic)),
                                  DataCell(Text(doctor)),
                                  DataCell(Text(fee)),
                                  DataCell(Text(date)),
                                  DataCell(Text(time)),
                                  DataCell(Text(duration)),
                                  DataCell(Text(status)),
                                  DataCell(
                                    Row(
                                      children: [
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'cancel') {
                                              await _updateStatus(
                                                doc.reference,
                                                'Cancelled',
                                              );
                                            } else if (value == 'complete') {
                                              await _updateStatus(
                                                doc.reference,
                                                'Completed',
                                              );
                                            } else if (value == 'admit') {
                                              await _updateStatus(
                                                doc.reference,
                                                'Admitted',
                                              );
                                            } else if (value == 'history') {
                                              _openHistory(
                                                patient,
                                                phone,
                                                mrNumber,
                                                data['doctorUid'], // <- add this
                                              );
                                            } else if (value == 'invoice') {
                                              _openInvoice(doc.id, data);
                                            } else if (value ==
                                                'prescription') {
                                              _openPrescription(doc.id, data);
                                            }
                                          },
                                          itemBuilder:
                                              (context) => const [
                                                PopupMenuItem(
                                                  value: 'complete',
                                                  child: Text('Mark Complete'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'cancel',
                                                  child: Text(
                                                    'Cancel Appointment',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'admit',
                                                  child: Text('Admit Patient'),
                                                ),
                                                PopupMenuDivider(),
                                                PopupMenuItem(
                                                  value: 'history',
                                                  child: Text('History'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'invoice',
                                                  child: Text('Invoice'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'prescription',
                                                  child: Text('Prescription'),
                                                ),
                                              ],
                                          child: const Icon(Icons.more_vert),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (_) => AlertDialog(
                                                    title: const Text(
                                                      'Confirm delete',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete this appointment?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text('No'),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Yes',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (confirm == true) {
                                              await doc.reference.delete();
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Appointment deleted',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
