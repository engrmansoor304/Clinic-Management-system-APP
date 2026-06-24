import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class staffadmitt extends StatefulWidget {
  const staffadmitt({super.key});

  @override
  State<staffadmitt> createState() => _staffadmittState();
}

class _staffadmittState extends State<staffadmitt> {
  DateTime selectedDate = DateTime.now();
  String? selectedDoctor;

  @override
  Widget build(BuildContext context) {
    // Selected date ko format karne ke liye (UI me)
    final dateFormatted = DateFormat('yyyy-MM-dd').format(selectedDate);

    // 🔹 Define start and end of day for filtering
    final startOfDay = Timestamp.fromDate(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        0,
        0,
        0,
      ),
    );
    final endOfDay = Timestamp.fromDate(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      ),
    );

    // 🔹 Firestore query
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('admittedPatients')
        .where('admitDate', isGreaterThanOrEqualTo: startOfDay)
        .where('admitDate', isLessThanOrEqualTo: endOfDay);

    if (selectedDoctor != null && selectedDoctor != 'All Doctors') {
      query = query.where('doctor', isEqualTo: selectedDoctor);
    }

    // ... baaki widget tree (Scaffold, StreamBuilder, etc.)

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admitted Patients'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top Filters (Date + Doctor)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDatePicker(context, dateFormatted),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildDoctorDropdown()),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 Table with admitted patients
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: query.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        );
                      }

                      final patients = snapshot.data?.docs ?? [];

                      if (patients.isEmpty) {
                        return const Center(
                          child: Text(
                            'No admitted patients for this date.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey.shade200,
                          ),
                          columnSpacing: 25,
                          dataRowHeight: 60,
                          columns: const [
                            DataColumn(label: Text("M.R#")),
                            DataColumn(label: Text("Name")),
                            DataColumn(label: Text("Doctor")),
                            DataColumn(label: Text("Visit Time")),
                            DataColumn(label: Text("Phone")),
                            DataColumn(label: Text("Status")),
                            DataColumn(label: Text("Actions")),
                          ],
                          rows:
                              patients.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DataRow(
                                  color:
                                      data['status'] == 'Admitted'
                                          ? MaterialStateProperty.all(
                                            Colors.green.shade50,
                                          )
                                          : null,
                                  cells: [
                                    DataCell(
                                      Text("${data['mrNumber'] ?? '-'}"),
                                    ),
                                    DataCell(Text("${data['name'] ?? '-'}")),
                                    DataCell(Text("${data['doctor'] ?? '-'}")),
                                    DataCell(
                                      Text("${data['visitTime'] ?? '-'}"),
                                    ),
                                    DataCell(Text("${data['phone'] ?? '-'}")),
                                    DataCell(
                                      Text(
                                        "${data['status'] ?? 'Admitted'}",
                                        style: TextStyle(
                                          color:
                                              (data['status'] == 'Discharged')
                                                  ? Colors.red
                                                  : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          _buildActionIcon(
                                            Icons.edit,
                                            Colors.blueGrey,
                                            () => _editPatient(
                                              context,
                                              doc.id,
                                              data,
                                            ),
                                          ),
                                          _buildActionIcon(
                                            Icons.info_outline,
                                            Colors.teal,
                                            () => _showDetails(context, data),
                                          ),
                                          _buildActionIcon(
                                            Icons.logout,
                                            Colors.red,
                                            () => _dischargePatient(
                                              context,
                                              doc.id,
                                            ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Date Picker
  Widget _buildDatePicker(BuildContext context, String formatted) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: formatted),
      decoration: InputDecoration(
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
    );
  }

  // 🔹 Doctor Dropdown (Dynamic from Firestore)
  // Doctor Dropdown
  Widget _buildDoctorDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final doctors =
            snapshot.data!.docs.map((d) => d['name'] as String).toList();

        return DropdownButtonFormField<String>(
          value: selectedDoctor, // ye value null ya doctor name persist kare
          hint: const Text("Select Doctor"),
          items: [
            DropdownMenuItem(value: null, child: Text("All Doctors")),
            ...doctors.map(
              (doc) => DropdownMenuItem(value: doc, child: Text(doc)),
            ),
          ],
          onChanged: (val) {
            setState(() => selectedDoctor = val); // persist kare
          },
        );
      },
    );
  }

  // 🔹 Reusable Action Icon
  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // 🔹 Edit Patient Info
  void _editPatient(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(text: data['name']);
    final phoneCtrl = TextEditingController(text: data['phone']);
    final statusCtrl = TextEditingController(text: data['status']);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Patient"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field("Name", nameCtrl),
                _field("Phone", phoneCtrl),
                _field("Status", statusCtrl),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('admittedPatients')
                      .doc(id)
                      .update({
                        'name': nameCtrl.text,
                        'phone': phoneCtrl.text,
                        'status': statusCtrl.text,
                      });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  // 🔹 Show Details
  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Patient Details"),
            content: Text(
              "Name: ${data['name']}\n"
              "Doctor: ${data['doctor']}\n"
              "Phone: ${data['phone']}\n"
              "Visit Time: ${data['visitTime']}\n"
              "Status: ${data['status'] ?? 'Admitted'}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  // 🔹 Discharge Patient
  void _dischargePatient(BuildContext context, String id) async {
    await FirebaseFirestore.instance
        .collection('admittedPatients')
        .doc(id)
        .update({'status': 'Discharged'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Patient discharged successfully")),
    );
  }

  // 🔹 Field Builder
  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
