import 'package:clinic_portal/login.dart';
import 'package:clinic_portal/staff/appstaff.dart';
import 'package:clinic_portal/staff/book_appoinment.dart';
import 'package:clinic_portal/staff/drstaff.dart';
import 'package:clinic_portal/staff/patientstaff.dart';
import 'package:clinic_portal/staff/sett.dart';
import 'package:clinic_portal/staff/staffadmit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? staffData;

  String staffName = FirebaseAuth.instance.currentUser?.displayName ?? 'Staff';
  int selectedTabIndex = 0;
  late TabController _tabController;

  final List<Tab> tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Confirmed'),
    Tab(text: 'Checked-in'),
    Tab(text: 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedTabIndex = _tabController.index;
        });
      }
    });

    fetchStaffData();
  }

  Future<void> fetchStaffData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          staffData = doc.data();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMenuDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF4DB6AC), // <-- entire drawer background color
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF4DB6AC), // same as drawer background
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.indigo),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        staffData != null ? staffData!['name'] : 'Staff',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Staff Panel",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white),
              title: const Text(
                "Dashboard",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StaffDashboard()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
              ),
              title: const Text(
                "Create Appointment",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const staffappointment()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text(
                "Patients",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Patientstaff()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.local_hospital_outlined,
                color: Colors.white,
              ),
              title: const Text(
                "Doctors",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Drstaff()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined, color: Colors.white),
              title: const Text(
                "Appointment History",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Appstaff()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: Colors.white),
              title: const Text(
                "Admit Patients",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const staffadmitt()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: Colors.white),
              title: const Text(
                "Settings",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const setstaff()),
                );
              },
            ),

            const Spacer(),
            const Divider(color: Colors.white70),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      drawer: _buildMenuDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE9EEF9),
              child: Icon(Icons.calendar_today, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $staffName!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.yellow),
            onPressed: () {
              Text("There is no new notification");
            },
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Check-in Patient'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final newAppointment = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const staffappointment(),
                ),
              );

              if (newAppointment != null && newAppointment is Appointment) {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .add({
                      'patient': newAppointment.patientName,
                      'doctor': newAppointment.doctorName,
                      'time': newAppointment.time,
                      'status': newAppointment.status.name,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Appointment'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('appointments')
                      .snapshots(),
              builder: (context, snapshot) {
                int totalAppointments = 0;
                int totalPatientsToday = 0;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  totalAppointments = docs.length;
                  final today = DateTime.now();

                  totalPatientsToday =
                      docs.where((doc) {
                        final dateStr = doc['date'] ?? ''; // "28-11-2025"
                        final timeStr = doc['time'] ?? ''; // "11:00 AM"

                        if (dateStr.isEmpty || timeStr.isEmpty) return false;

                        try {
                          final dayParts = dateStr.split(
                            '-',
                          ); // ["28", "11", "2025"]
                          final hourMin = DateFormat(
                            'hh:mm a',
                          ).parse(timeStr); // parses "11:00 AM"

                          final appointmentTime = DateTime(
                            int.parse(dayParts[2]), // year
                            int.parse(dayParts[1]), // month
                            int.parse(dayParts[0]), // day
                            hourMin.hour,
                            hourMin.minute,
                          );

                          final today = DateTime.now();
                          return appointmentTime.year == today.year &&
                              appointmentTime.month == today.month &&
                              appointmentTime.day == today.day;
                        } catch (e) {
                          return false;
                        }
                      }).length;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('doctors')
                          .snapshots(),
                  builder: (context, doctorSnapshot) {
                    int totalDoctors =
                        doctorSnapshot.hasData
                            ? doctorSnapshot.data!.docs.length
                            : 0;

                    return ResponsiveRow(
                      children: [
                        SummaryCard(
                          title: 'Total Patients Today',
                          value:
                              totalPatientsToday > 0
                                  ? '$totalPatientsToday'
                                  : 'No data',
                          icon: Icons.people_alt,
                        ),
                        SummaryCard(
                          title: 'Total Appointments',
                          value:
                              totalAppointments > 0
                                  ? '$totalAppointments'
                                  : 'No data',
                          icon: Icons.event_note,
                        ),
                        SummaryCard(
                          title: 'Available Doctors',
                          value: totalDoctors > 0 ? '$totalDoctors' : 'No data',
                          icon: Icons.medical_services,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Appointments",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isMobile)
                        Row(
                          children: [
                            FilterChipWidget(
                              icon: Icons.remove_red_eye,
                              label: 'All',
                              selected: selectedTabIndex == 0,
                              onTap: () => _tabController.index = 0,
                            ),
                            const SizedBox(width: 6),
                            FilterChipWidget(
                              icon: Icons.check_circle,
                              label: 'Confirmed',
                              selected: selectedTabIndex == 1,
                              onTap: () => _tabController.index = 1,
                            ),
                            const SizedBox(width: 6),
                            FilterChipWidget(
                              icon: Icons.login,
                              label: 'Checked-in',
                              selected: selectedTabIndex == 2,
                              onTap: () => _tabController.index = 2,
                            ),
                            const SizedBox(width: 6),
                            FilterChipWidget(
                              icon: Icons.done_all,
                              label: 'Completed',
                              selected: selectedTabIndex == 3,
                              onTap: () => _tabController.index = 3,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    tabs: tabs,
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey[700],
                    indicatorColor: Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('appointments')
                            .orderBy('time')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final appointments =
                          docs
                              .map((doc) => Appointment.fromFirestore(doc))
                              .toList();

                      final filtered = switch (selectedTabIndex) {
                        1 =>
                          appointments
                              .where(
                                (a) => a.status == AppointmentStatus.confirmed,
                              )
                              .toList(),
                        2 =>
                          appointments
                              .where(
                                (a) => a.status == AppointmentStatus.checkedIn,
                              )
                              .toList(),
                        3 =>
                          appointments
                              .where(
                                (a) => a.status == AppointmentStatus.completed,
                              )
                              .toList(),
                        _ => appointments,
                      };

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No appointments scheduled for today.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children:
                            filtered
                                .map(
                                  (a) => AppointmentRow(
                                    appointment: a,
                                    isWide:
                                        MediaQuery.of(context).size.width > 700,
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -----------------------
   Models
------------------------*/
class Appointment {
  final String id;
  final String time;
  final String patientName;
  final String doctorName;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.time,
    required this.patientName,
    required this.doctorName,
    required this.status,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      time: data['time'] ?? '',
      patientName: data['patient'] ?? '',
      doctorName: data['doctor'] ?? '',
      status: _statusFromString(data['status'] ?? 'confirmed'),
    );
  }

  static AppointmentStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'checked-in':
        return AppointmentStatus.checkedIn;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.confirmed;
    }
  }
}

enum AppointmentStatus { confirmed, checkedIn, completed }

/* -----------------------
   UI Components
------------------------*/
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveRow({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int columns = width >= 600 ? (width >= 1100 ? 3 : 2) : 1;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children:
          children
              .map(
                (child) => SizedBox(
                  width:
                      columns == 1
                          ? double.infinity
                          : (width - (16 * (columns - 1)) - 48) / columns,
                  child: child,
                ),
              )
              .toList(),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEAF1FF),
            child: Icon(icon, color: Colors.indigo, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentRow extends StatelessWidget {
  final Appointment appointment;
  final bool isWide;
  const AppointmentRow({
    required this.appointment,
    required this.isWide,
    super.key,
  });

  Color statusColor(AppointmentStatus s) => switch (s) {
    AppointmentStatus.confirmed => Colors.blue,
    AppointmentStatus.checkedIn => Colors.green,
    AppointmentStatus.completed => Colors.grey,
  };

  String statusText(AppointmentStatus s) => switch (s) {
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.checkedIn => 'Checked-in',
    AppointmentStatus.completed => 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    appointment.time,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFF0F4FF),
                        child: Icon(Icons.person, color: Colors.indigo),
                      ),
                      const SizedBox(width: 10),
                      Text(appointment.patientName),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    appointment.doctorName,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(
                          appointment.status,
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText(appointment.status),
                        style: TextStyle(
                          color: statusColor(appointment.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                appointment.time,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF0F4FF),
                child: Icon(Icons.person, size: 18, color: Colors.indigo),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.medical_services, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(appointment.doctorName)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor(appointment.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText(appointment.status),
                  style: TextStyle(
                    color: statusColor(appointment.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.remove_red_eye_outlined),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
        ],
      );
    }
  }
}

class FilterChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterChipWidget({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? Colors.indigo.withOpacity(0.18) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.indigo : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.indigo : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
