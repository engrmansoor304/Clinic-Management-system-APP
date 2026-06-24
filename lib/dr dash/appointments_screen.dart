import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'prescription_screen.dart';
import 'invoice_screen.dart';

class DrAppointments extends StatefulWidget {
  const DrAppointments({super.key});

  @override
  State<DrAppointments> createState() => _DrAppointmentsState();
}

class _DrAppointmentsState extends State<DrAppointments> {
  String selectedFilter = "Pending"; // default filter
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Doctor UID filter
    final appointmentsQuery = FirebaseFirestore.instance
        .collection('appointments')
        .where('appointmentType', isEqualTo: 'Physical')
        .where('doctorUid', isEqualTo: currentUser!.uid);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Appointments",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _filterDropdown(),
            ],
          ),
          const SizedBox(height: 20),

          // Appointment List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: appointmentsQuery.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }

                final allAppointments = snap.data!.docs;
                final filteredAppointments =
                    allAppointments.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == selectedFilter;
                    }).toList();

                if (filteredAppointments.isEmpty) {
                  return const Center(child: Text("No appointments found."));
                }

                return ListView.builder(
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final doc = filteredAppointments[index];
                    final a = doc.data() as Map<String, dynamic>;
                    final docId = doc.id; // Firestore document ID
                    return _appointmentCard(context, a, docId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter Dropdown
  Widget _filterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: selectedFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
        items: const [
          DropdownMenuItem(value: "Pending", child: Text("Pending")),
          DropdownMenuItem(value: "Completed", child: Text("Completed")),
        ],
        onChanged: (value) {
          setState(() => selectedFilter = value!);
        },
      ),
    );
  }

  // Appointment Card
  Widget _appointmentCard(
    BuildContext context,
    Map<String, dynamic> a,
    String docId,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['patient'] ?? a['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        docId,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(a['status'] ?? ''),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📅 ${a['date'] ?? ''}  ⏰ ${a['time'] ?? ''}"),
                Text(
                  "💸 PKR ${a['amount'] ?? 0}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ Mark Completed button for Pending
                if (a['status'] == 'Pending')
                  _smallButton(
                    "Mark Completed",
                    Icons.check_circle,
                    Colors.green,
                    () async {
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc(docId)
                          .update({'status': 'Completed'});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Appointment marked as Completed"),
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(width: 10),
                _smallButton(
                  "Prescription",
                  Icons.description,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PrescriptionScreen(
                            appointmentData: a,
                            appointmentId: docId,
                            patientData: {},
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _smallButton(
                  "Invoice",
                  Icons.receipt_long,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => InvoiceScreen(
                            appointmentId: docId,
                            appointmentData: a, // pass the appointment map here
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Status Badge
  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case "Completed":
        color = Colors.green;
        break;
      case "Pending":
        color = Colors.orange;
        break;
      default:
        color = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Small Button
  Widget _smallButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
