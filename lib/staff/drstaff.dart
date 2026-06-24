import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinic_portal/staff/book_appoinment.dart'; // Your appointment screen

class Drstaff extends StatelessWidget {
  const Drstaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctors List"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctors = snapshot.data!.docs;

          if (doctors.isEmpty) {
            return const Center(
              child: Text(
                "No doctors available.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown';
              final speciality = data['speciality'] ?? 'Not specified';
              final phone = data['phone'] ?? 'N/A';
              final email = data['email'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF1FF),
                    child: Icon(Icons.medical_services, color: Colors.indigo),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    "Speciality: $speciality\nPhone: $phone\nEmail: $email",
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // Navigate to appointment creation screen
                      final newAppointment = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => staffappointment(
                                preselectedDoctor: name, // pass doctor name
                              ),
                        ),
                      );

                      if (newAppointment != null) {
                        // Optionally handle after creation, e.g., show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appointment Created!')),
                        );
                      }
                    },
                    child: const Text('Create Appointment'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
