import 'package:clinic_portal/dr%20dash/invoice_screen.dart';
import 'package:clinic_portal/dr%20dash/prescription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum ConsultationStatus { pending, active, completed }

class ConsultationItem {
  final String id;
  final String name;
  final String time;
  final String date;
  final String phone;
  final ConsultationStatus status;

  ConsultationItem({
    required this.id,
    required this.name,
    required this.time,
    required this.date,
    required this.phone,
    required this.status,
  });
}

class VideoConsultationScreen extends StatefulWidget {
  final String doctorUid;
  const VideoConsultationScreen({Key? key, required this.doctorUid})
    : super(key: key);

  @override
  State<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Stream<QuerySnapshot> get _videoAppointmentsStream =>
      FirebaseFirestore.instance
          .collection('appointments')
          .where('appointmentType', isEqualTo: 'Online')
          .where('doctorUid', isEqualTo: widget.doctorUid)
          .snapshots();

  ConsultationStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ConsultationStatus.active;
      case 'completed':
        return ConsultationStatus.completed;
      default:
        return ConsultationStatus.pending;
    }
  }

  List<ConsultationItem> _filterByStatus(
    QuerySnapshot snapshot,
    ConsultationStatus statusFilter,
  ) {
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ConsultationItem(
            id: doc.id,
            name: data['patient'] ?? '',
            time: data['time'] ?? '',
            date: data['date'] ?? '',
            phone: data['phone'] ?? '',
            status: _mapStatus(data['status'] ?? 'Pending'),
          );
        })
        .where((item) => item.status == statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultations'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _videoAppointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Online Appointments Found"));
          }

          final pending = _filterByStatus(
            snapshot.data!,
            ConsultationStatus.pending,
          );
          final active = _filterByStatus(
            snapshot.data!,
            ConsultationStatus.active,
          );
          final completed = _filterByStatus(
            snapshot.data!,
            ConsultationStatus.completed,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListSection(pending, ConsultationStatus.pending),
              _buildListSection(active, ConsultationStatus.active),
              _buildListSection(completed, ConsultationStatus.completed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListSection(
    List<ConsultationItem> data,
    ConsultationStatus currentStatus,
  ) {
    if (data.isEmpty) {
      return const Center(
        child: Text("No Appointments", style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        // Fetch full appointment document
        final appointmentDoc = FirebaseFirestore.instance
            .collection('appointments')
            .doc(item.id);

        return FutureBuilder<DocumentSnapshot>(
          future: appointmentDoc.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(title: Text("Loading..."));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const ListTile(title: Text("Appointment data not found"));
            }

            final dataMap = snapshot.data!.data() as Map<String, dynamic>?;

            if (dataMap == null) {
              return const ListTile(title: Text("Appointment data is empty"));
            }

            final patientData = {
              'patient': dataMap['patient'] ?? 'N/A',
              'age': dataMap['age'] ?? '-',
              'gender': dataMap['gender'] ?? 'Unknown',
              'cnic': dataMap['cnic'] ?? '-',
              'amount': dataMap['amount'] ?? 0,
              'date': dataMap['date'] ?? '',
              'time': dataMap['time'] ?? '',
            };

            return Card(
              child: ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green, size: 28),
                  onPressed: () => _openWhatsApp(item.phone),
                ),
                title: Text(item.name),
                subtitle: Text("${item.date}  |  ${item.time}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _badgeColor(item.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (currentStatus != ConsultationStatus.completed)
                      ElevatedButton(
                        onPressed: () => _markAsCompleted(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Mark Done"),
                      ),
                    const SizedBox(width: 6),
                    // Prescription Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PrescriptionScreen(
                                  appointmentId: item.id,
                                  appointmentData: dataMap,
                                  patientData: patientData,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Prescription"),
                    ),
                    const SizedBox(width: 6),
                    // Invoice Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => InvoiceScreen(
                                  appointmentId: item.id,
                                  appointmentData: dataMap!,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Invoice"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markAsCompleted(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(id)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment marked as Completed ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No phone number found")));
      return;
    }

    String formattedNumber =
        phoneNumber.startsWith("+") ? phoneNumber : "+92$phoneNumber";

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$formattedNumber?text=Hello%20from%20Doctor!",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("WhatsApp not installed")));
    }
  }

  Color _badgeColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.pending:
        return Colors.orange;
      case ConsultationStatus.active:
        return Colors.green;
      case ConsultationStatus.completed:
        return Colors.grey;
    }
  }
}
