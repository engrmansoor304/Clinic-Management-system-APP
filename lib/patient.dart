import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String patientName;
  final String phone;
  final String mrNumber;

  const PatientHistoryScreen({
    super.key,
    required this.patientName,
    required this.phone,
    required this.mrNumber,
    required String doctorUid,
  });

  @override
  Widget build(BuildContext context) {
    final appointmentsQuery = FirebaseFirestore.instance
        .collection('appointments')
        .where('phone', isEqualTo: phone)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient History'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('M.R#: ${mrNumber.isEmpty ? "-" : mrNumber}'),
                          Text('Mobile: $phone'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: appointmentsQuery.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No record found!'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final data = d.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          '${data['date'] ?? ''}  ${data['time'] ?? ''}',
                        ),
                        subtitle: Text(
                          'Doctor: ${data['doctor'] ?? ''}\nStatus: ${data['status'] ?? ''}',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Optionally open appointment details
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
