// patients_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // for opening Dropbox PDF links

class Patientstaff extends StatefulWidget {
  const Patientstaff({super.key});

  @override
  State<Patientstaff> createState() => _PatientstaffState();
}

class _PatientstaffState extends State<Patientstaff> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("All Patients History"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("appointments")
                .where("status", isEqualTo: "Completed")
                .orderBy("createdAt", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(
              child: Text("No completed appointments found."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final ap = appointments[index].data() as Map<String, dynamic>;
              final id = appointments[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    ap['patient'] ?? "Unknown Patient",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text("Doctor: ${ap['doctor'] ?? 'N/A'}"),
                      Text("Date: ${ap['date']}  Time: ${ap['time']}"),
                      Text("Fee: PKR ${ap['fee'] ?? '-'}"),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "prescription") {
                        _openPdf(ap['prescriptionDropboxLink']);
                      } else if (value == "invoice") {
                        _openPdf(ap['invoiceDropboxLink']);
                      } else if (value == "edit") {
                        _editPatient(context, ap['patientId']);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: "prescription",
                            child: Row(
                              children: [
                                Icon(Icons.note_alt, color: Colors.teal),
                                SizedBox(width: 8),
                                Text("View Prescription"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: "invoice",
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.indigo),
                                SizedBox(width: 8),
                                Text("View Invoice"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: "edit",
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.grey),
                                SizedBox(width: 8),
                                Text("Edit Patient"),
                              ],
                            ),
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

  // 🔹 Open Dropbox PDF link
  void _openPdf(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PDF not available")));
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open PDF")));
    }
  }

  // 🔹 Edit Patient Info
  void _editPatient(BuildContext context, String? patientId) async {
    if (patientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Patient ID not available")));
      return;
    }

    final patientDoc =
        await FirebaseFirestore.instance
            .collection("patients")
            .doc(patientId)
            .get();

    if (!patientDoc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Patient record not found")));
      return;
    }

    final p = patientDoc.data()!;
    final nameCtrl = TextEditingController(text: p['name']);
    final phoneCtrl = TextEditingController(text: p['phone']);
    final ageCtrl = TextEditingController(text: p['age'].toString());

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Patient"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field("Name", nameCtrl),
                _field("Phone", phoneCtrl),
                _field("Age", ageCtrl),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                ),
                child: const Text("Save"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("patients")
                      .doc(patientId)
                      .update({
                        "name": nameCtrl.text,
                        "phone": phoneCtrl.text,
                        "age": int.tryParse(ageCtrl.text) ?? 0,
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Patient updated successfully"),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
