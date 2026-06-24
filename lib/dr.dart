import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _newDoctor = {
    "name": "",
    "speciality": "",
    "phone": "",
    "email": "",
    "pmdc": "",
  };

  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _dayOptions = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  // -------------------- ADD DOCTOR DIALOG --------------------
  void _showAddDoctorDialog() {
    _selectedDays = [];
    _startTime = null;
    _endTime = null;

    final _passwordController = TextEditingController();
    final _feeController = TextEditingController();

    // Save current admin info
    final currentUser = FirebaseAuth.instance.currentUser!;
    final adminEmail = currentUser.email!;
    // ⚠️ You'll need admin password here. For testing, you can ask the admin to enter it in a dialog or store it securely
    String adminPassword = "";

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.teal.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add New Doctor",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField("Name", Icons.person),
                      _buildTextField("Speciality", Icons.medical_services),
                      _buildTextField(
                        "Phone",
                        Icons.phone,
                        keyboard: TextInputType.phone,
                      ),
                      _buildTextField(
                        "Email",
                        Icons.email,
                        keyboard: TextInputType.emailAddress,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.teal,
                          ),
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        obscureText: true,
                        validator:
                            (v) =>
                                v == null || v.length < 6
                                    ? "Password must be at least 6 characters"
                                    : null,
                      ),
                      _buildTextField("PMDC", Icons.badge),
                      _buildTextFieldWithController(
                        "Fee",
                        Icons.money,
                        _feeController,
                        TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Available Days:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            _dayOptions.map((day) {
                              return FilterChip(
                                label: Text(day),
                                selected: _selectedDays.contains(day),
                                selectedColor: Colors.teal.shade100,
                                onSelected: (selected) {
                                  setState(() {
                                    selected
                                        ? _selectedDays.add(day)
                                        : _selectedDays.remove(day);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _timeButton(
                            "Start Time",
                            _startTime,
                            (picked) => setState(() => _startTime = picked),
                          ),
                          _timeButton(
                            "End Time",
                            _endTime,
                            (picked) => setState(() => _endTime = picked),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text("Save Doctor"),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedDays.isEmpty ||
                                  _startTime == null ||
                                  _endTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select days and working time",
                                    ),
                                  ),
                                );
                                return;
                              }

                              _formKey.currentState!.save();

                              try {
                                // 🔹 Create doctor user in Firebase Auth
                                final userCredential = await FirebaseAuth
                                    .instance
                                    .createUserWithEmailAndPassword(
                                      email: _newDoctor["email"],
                                      password: _passwordController.text.trim(),
                                    );

                                final uid = userCredential.user!.uid;

                                // 🔹 Save doctor in 'users' collection
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .set({
                                      "role": "Doctor",
                                      "email": _newDoctor["email"],
                                      "name": _newDoctor["name"],
                                    });

                                // 🔹 Save doctor details in 'doctors' collection
                                await FirebaseFirestore.instance
                                    .collection('doctors')
                                    .doc(uid)
                                    .set({
                                      ..._newDoctor,
                                      "uid": uid,
                                      "availableDays": _selectedDays,
                                      "startTime": _formatTime(_startTime!),
                                      "endTime": _formatTime(_endTime!),
                                      "fee": _feeController.text.trim(),
                                      "available": true,
                                    });

                                // 🔹 Sign back in as admin
                                await FirebaseAuth.instance.signOut();
                                if (adminPassword.isNotEmpty) {
                                  await FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                        email: adminEmail,
                                        password: adminPassword,
                                      );
                                }

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Doctor added successfully"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.toString()}"),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // -------------------- TEXT FIELD --------------------
  Widget _buildTextField(
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? "Enter $label" : null,
        onSaved: (v) => _newDoctor[label.toLowerCase()] = v ?? "",
      ),
    );
  }

  Widget _buildTextFieldWithController(
    String label,
    IconData icon,
    TextEditingController controller,
    TextInputType keyboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  // -------------------- TIME PICKER --------------------
  Widget _timeButton(
    String label,
    TimeOfDay? selectedTime,
    Function(TimeOfDay) onPicked,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: const BorderSide(color: Colors.teal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.access_time, color: Colors.teal),
      label: Text(
        selectedTime == null ? label : _formatTime(selectedTime),
        style: const TextStyle(color: Colors.teal),
      ),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  String _formatTime(TimeOfDay t) =>
      "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? "AM" : "PM"}";

  // -------------------- MAIN SCREEN --------------------
  @override
  Widget build(BuildContext context) {
    final doctorsStream =
        FirebaseFirestore.instance.collection('doctors').snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 3,
        title: const Text(
          "Doctors",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _showAddDoctorDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: doctorsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No doctors found",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.person, color: Colors.teal),
                  ),
                  title: Text(
                    data["name"] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${data["speciality"] ?? "No speciality"}\n"
                      "Days: ${(data["availableDays"] ?? []).join(", ")}\n"
                      "Time: ${data["startTime"]} - ${data["endTime"]}\n"
                      "Fee: ${data["fee"] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () => _showDoctorDetails(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final uid = data["uid"];

                          // 🔥 SHOW CONFIRMATION DIALOG
                          final confirm = await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text(
                                    "Delete Doctor?",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete Dr. ${data["name"]}? This action cannot be undone.",
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("Delete"),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm != true) return; // ❌ user canceled

                          try {
                            // Step 1: Delete doctor from Firestore (doctors collection)
                            await doc.reference.delete();

                            // Step 2: Delete doctor from users collection
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .delete();

                            // Step 3: Queue Auth user deletion (server-side)
                            await FirebaseFirestore.instance
                                .collection('auth_deletion_requests')
                                .add({
                                  "uid": uid,
                                  "timestamp": FieldValue.serverTimestamp(),
                                });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Doctor ${data["name"]} deleted successfully",
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error deleting doctor: $e"),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------- DOCTOR DETAILS --------------------
  void _showDoctorDetails(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final feeController = TextEditingController(text: data["fee"]);
    final startController = TextEditingController(
      text: data["startTime"] ?? "",
    );
    final endController = TextEditingController(text: data["endTime"] ?? "");
    List<String> selectedDays = List<String>.from(
      data["availableDays"] ?? <String>[],
    );

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["name"],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow("Speciality", data["speciality"]),
                    _infoRow("Phone", data["phone"]),
                    _infoRow("Email", data["email"]),
                    _infoRow("PMDC", data["pmdc"]),
                    const Divider(height: 25, color: Colors.teal),
                    const Text(
                      "Available Days:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children:
                          _dayOptions.map((day) {
                            return FilterChip(
                              label: Text(day),
                              selected: selectedDays.contains(day),
                              selectedColor: Colors.teal.shade100,
                              onSelected: (val) {
                                setState(() {
                                  val
                                      ? selectedDays.add(day)
                                      : selectedDays.remove(day);
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _editableField("Start Time", startController),
                    const SizedBox(height: 8),
                    _editableField("End Time", endController),
                    const SizedBox(height: 8),
                    _editableField(
                      "Consultation Fee",
                      feeController,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await doc.reference.update({
                            "availableDays": selectedDays,
                            "startTime": startController.text,
                            "endTime": endController.text,
                            "fee": feeController.text,
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _editableField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
