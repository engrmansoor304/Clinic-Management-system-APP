import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  // 🔹 Delete staff from Firebase
  Future<void> _deleteStaff(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Staff"),
            content: const Text(
              "Are you sure you want to delete this staff member?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Staff deleted successfully")),
      );
    }
  }

  // 🔹 Preview staff details dialog
  void _showStaffDetailsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Staff Details",
            style: TextStyle(color: Colors.teal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 Name: ${data['name'] ?? ''}"),
              Text("📧 Email: ${data['email'] ?? ''}"),
              Text("📱 Phone: ${data['phone'] ?? ''}"),
              Text("💼 Designation: ${data['designation'] ?? ''}"),
              Text(
                "🕓 Joined: ${data['createdAt'] != null ? data['createdAt'].toDate().toString().split(' ')[0] : 'N/A'}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _newStaff = {
    "name": "",
    "email": "",
    "phone": "",
    "designation": "",
    "password": "",
  };

  String _searchQuery = "";

  // Appointment Controllers
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String? _selectedDoctor;
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "09:00 AM - 09:30 AM",
    "09:30 AM - 10:00 AM",
    "10:00 AM - 10:30 AM",
    "10:30 AM - 11:00 AM",
    "11:00 AM - 11:30 AM",
    "11:30 AM - 12:00 PM",
    "12:00 PM - 12:30 PM",
    "12:30 PM - 01:00 PM",
  ];

  // ---------------------- ADD STAFF ----------------------
  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add New Staff",
            style: TextStyle(color: Colors.teal),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField("Name"),
                  _buildTextField("Email"),
                  _buildTextField("Phone"),
                  _buildTextField("Designation"),
                  _buildTextField("Password", isPassword: true),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: _addStaffToFirebase,
              child: const Text("Add Staff"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStaffToFirebase() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final currentUser = FirebaseAuth.instance.currentUser!;
    final adminEmail = currentUser.email!;

    // You need to ask admin password for this to work
    String adminPassword = "admin123"; // ⚠️ Store securely

    try {
      // 1️⃣ Create staff
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _newStaff["email"]!,
            password: _newStaff["password"]!,
          );
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "uid": uid,
        "name": _newStaff["name"],
        "email": _newStaff["email"],
        "phone": _newStaff["phone"],
        "designation": _newStaff["designation"],
        "password": _newStaff["password"],
        "role": "Staff",
        "createdAt": DateTime.now(),
      });

      // 2️⃣ Sign back in as admin
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Staff added successfully!")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ ${e.message}")));
    }
  }

  // ---------------------- CREATE APPOINTMENT ----------------------
  void _showCreateAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Create Appointment",
            style: TextStyle(color: Colors.teal),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildAppointmentField(
                  "Patient Name",
                  _patientNameController,
                  Icons.person,
                ),
                _buildAppointmentField(
                  "Phone Number",
                  _phoneController,
                  Icons.phone,
                  type: TextInputType.phone,
                ),
                _buildAppointmentField(
                  "Appointment Duration (e.g. 30 mins)",
                  _durationController,
                  Icons.timer,
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'Doctor')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      );
                    }
                    final doctors = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Doctor",
                        prefixIcon: const Icon(
                          Icons.medical_services,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: _selectedDoctor,
                      items:
                          doctors.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: data["name"],
                              child: Text(data["name"]),
                            );
                          }).toList(),
                      onChanged: (v) => setState(() => _selectedDoctor = v),
                    );
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Time Slot",
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: Colors.teal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedTimeSlot,
                  items:
                      _timeSlots
                          .map(
                            (slot) => DropdownMenuItem(
                              value: slot,
                              child: Text(slot),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedTimeSlot = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: _saveAppointment,
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAppointment() async {
    final name = _patientNameController.text.trim();
    final phone = _phoneController.text.trim();
    final duration = _durationController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        duration.isEmpty ||
        _selectedDoctor == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    // Store using the SAME field names as AppointmentsScreen
    await FirebaseFirestore.instance.collection('appointments').add({
      "patient": name,
      "phone": phone,
      "doctor": _selectedDoctor,
      "duration": duration,
      "time": _selectedTimeSlot,
      "date":
          "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      "status": "Pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    _patientNameController.clear();
    _phoneController.clear();
    _durationController.clear();
    _selectedDoctor = null;
    _selectedTimeSlot = null;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Appointment Created Successfully")),
    );
  }

  // ---------------------- STAFF TABLE ----------------------
  Widget _buildStaffTable() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Staff')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            );
          }

          final staffDocs =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['name'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.teal.shade100),
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Designation")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Phone")),
                DataColumn(label: Text("Actions")), // ✅ new column
              ],
              rows: List.generate(staffDocs.length, (i) {
                final doc = staffDocs[i];
                final data = doc.data() as Map<String, dynamic>;

                return DataRow(
                  cells: [
                    DataCell(Text("${i + 1}")),
                    DataCell(Text(data["name"] ?? "")),
                    DataCell(Text(data["designation"] ?? "")),
                    DataCell(Text(data["email"] ?? "")),
                    DataCell(Text(data["phone"] ?? "")),

                    // ✅ Actions column with preview & delete
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                            ),
                            tooltip: "Preview",
                            onPressed: () => _showStaffDetailsDialog(data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Delete",
                            onPressed: () => _deleteStaff(doc.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ---------------------- APPOINTMENT LIST ----------------------

  // ---------------------- HELPERS ----------------------
  Widget _buildAppointmentField(
    String label,
    TextEditingController c,
    IconData icon, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            isPassword ? Icons.lock : Icons.person,
            color: Colors.teal,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (v) => v == null || v.isEmpty ? "Enter $label" : null,
        onSaved: (v) => _newStaff[label.toLowerCase()] = v ?? "",
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search staff by name...",
        prefixIcon: const Icon(Icons.search, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  // ---------------------- MAIN ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Staff Management"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildStaffTable(),
                  // 🗑️ Removed appointment list
                  // const SizedBox(height: 20),
                  // _buildAppointmentList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Create Appointment'),
        onPressed: _showCreateAppointmentDialog,
      ),
    );
  }
}
