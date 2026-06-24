import 'package:clinic_portal/admitted.dart';
import 'package:clinic_portal/appointment.dart';
import 'package:clinic_portal/dr%20dash/doctor_dashboard%20(1).dart';

import 'package:clinic_portal/dr.dart';

import 'package:clinic_portal/login.dart';
import 'package:clinic_portal/patient_history.dart';
import 'package:clinic_portal/staff.dart';
import 'package:clinic_portal/staff/staff_dashboard.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAan3bNEgD1PcEnMGKb-Fy50ktHsELtqXY",
        authDomain: "clinic-dd27e.firebaseapp.com",
        projectId: "clinic-dd27e",
        storageBucket: "clinic-dd27e.firebasestorage.app",
        messagingSenderId: "1067331149761",
        appId: "1:1067331149761:web:951a3114b37cd51699d940",
        measurementId: "G-GDY7Y2LHL2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Clinic Portal ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User not logged in
        if (!snapshot.hasData) return const LoginScreen();

        final user = snapshot.data!;

        // Fetch user role
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snap.hasData || !snap.data!.exists) {
              return const LoginScreen();
            }

            final data = snap.data!.data() as Map<String, dynamic>;
            final role = data['role'];

            // 👇 Redirect based on role
            final normalizedRole = (role ?? '').toString().trim().toLowerCase();

            if (normalizedRole == 'admin') {
              return const DashboardShell();
            } else if (normalizedRole == 'doctor') {
              return DoctorDashboard();
            } else if (normalizedRole == 'staff') {
              return const StaffDashboard(); // 👈 add this line
            } else {
              print('⚠️ Unknown or missing role: $normalizedRole');
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

// ---------------- SHELL (Sidebar + Topbar) -----------------
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> menuItems = const [
    {
      'icon': Icons.dashboard_outlined,
      'label': 'Dashboard',
    }, // cleaner dashboard icon
    {
      'icon': Icons.medical_services,
      'label': 'Doctors',
    }, // medical icon for doctors
    {'icon': Icons.person_outline, 'label': 'Staff'}, // staff/person icon
    {
      'icon': Icons.event_available,
      'label': 'Appointments',
    }, // checkmark calendar
    {
      'icon': Icons.history_edu,
      'label': 'Patient History',
    }, // history icon suitable for records
    {
      'icon': Icons.local_hospital,
      'label': 'Clinic Admitted Patients',
    }, // hospital icon
  ];

  bool get isDesktop => MediaQuery.of(context).size.width > 950;

  void _onSelect(int index) {
    setState(() => selectedIndex = index);
    if (!isDesktop) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardScreen(),
      const DoctorScreen(),
      const StaffScreen(), // 👈 add this
      const AppointmentsScreen(),
      const PatientsHistoryScreen(),
      const AdmittedPatientsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'The Clinic Portal',
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.teal),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('There are no notifications.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.teal),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings screen coming soon!')),
                );
              } else if (value == 'logout') {
                setState(() => selectedIndex = 0); // reset to Dashboard
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),

      drawer: isDesktop ? null : Drawer(child: _sidebar()),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 250, child: _sidebar()),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: screens[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      color: const Color(0xFF4DB6AC),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Text(
                    " My Clinic ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white54, thickness: 1),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, i) {
                  final item = menuItems[i];
                  final selected = i == selectedIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => _onSelect(i),
                    ),
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

// ---------------- DASHBOARD SCREEN (UPGRADED UI) -----------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, doctorSnap) {
        return StreamBuilder(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Staff')
                  .snapshots(),

          builder: (context, staffSnap) {
            return StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection('appointments')
                      .snapshots(),
              builder: (context, apptSnap) {
                if (!doctorSnap.hasData ||
                    !staffSnap.hasData ||
                    !apptSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totals = {
                  'doctors':
                      doctorSnap.data!.docs.length, // from doctors collection
                  'staff':
                      staffSnap
                          .data!
                          .docs
                          .length, // from users collection filtered by role
                  'patients': apptSnap.data!.docs.length,
                };

                final List<double> revenueData = [
                  1000,
                  1500,
                  1800,
                  2500,
                  2200,
                  2600,
                  2900,
                ];
                final List<double> apptData = [5, 10, 20, 18, 25, 28, 30];

                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF)],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double maxWidth = constraints.maxWidth;
                            int crossAxisCount = maxWidth > 900 ? 4 : 2;
                            double cardWidth =
                                (maxWidth - (16 * (crossAxisCount - 1))) /
                                crossAxisCount;

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _statCard(
                                    Icons.medical_services,
                                    "Total Doctors",
                                    totals['doctors'].toString(),
                                    Colors.teal,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _statCard(
                                    Icons.group,
                                    "Total Staff",
                                    totals['staff'].toString(),
                                    Colors.indigo,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _statCard(
                                    Icons.people,
                                    "Appointments",
                                    totals['patients'].toString(),
                                    Colors.blue,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _subscribeCard(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _chartCard(
                                  "Revenue Overview",
                                  "\$4,500",
                                  "+12% from last month",
                                  Colors.teal,
                                  revenueData,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _chartCard(
                                  "Appointments Trends",
                                  "${totals['patients']} Appointments",
                                  "+8% from last week",
                                  Colors.blue,
                                  apptData,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _chartCard(
                                "Revenue Overview",
                                "\$4,500",
                                "+12% from last month",
                                Colors.teal,
                                revenueData,
                              ),
                              const SizedBox(height: 16),
                              _chartCard(
                                "Appointments Trends",
                                "${totals['patients']} Appointments",
                                "+8% from last week",
                                Colors.blue,
                                apptData,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscribeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal, Colors.tealAccent],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sms, color: Colors.white, size: 28),
          SizedBox(height: 12),
          Text(
            "Subscribe for Unlimited SMS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Upgrade your clinic notifications instantly.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    String title,
    String total,
    String changeText,
    Color color,
    List<double> chartData,
  ) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        chartData.length,
                        (i) => FlSpot(i.toDouble(), chartData[i]),
                      ),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.3), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Total: $total",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              changeText,
              style: const TextStyle(color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class SurgeonsDirectory extends StatefulWidget {
  const SurgeonsDirectory({super.key});

  @override
  State<SurgeonsDirectory> createState() => _SurgeonsDirectoryState();
}

class _SurgeonsDirectoryState extends State<SurgeonsDirectory> {
  String selectedDept = 'Cardiology';
  final List<Map<String, String>> surgeons = [
    {
      'name': 'Dr. Avtar Singh',
      'department': 'Cardiology',
      'image': 'assets/images/doctor1.png',
    },
    {
      'name': 'Dr. Gurpreet Kaur',
      'department': 'Neurology',
      'image': 'assets/images/doctor2.png',
    },
    {
      'name': 'Dr. Harmanpreet Singh',
      'department': 'Orthopedics',
      'image': 'assets/images/doctor3.png',
    },
    {
      'name': 'Dr. Manjit Sharma',
      'department': 'Oncology',
      'image': 'assets/images/doctor4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        surgeons.where((s) => s['department'] == selectedDept).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surgeons Directory'),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [Icon(Icons.notifications_none), SizedBox(width: 15)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, department...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _deptChip('Cardiology'),
                  const SizedBox(width: 8),
                  _deptChip('Neurology'),
                  const SizedBox(width: 8),
                  _deptChip('Orthopedics'),
                  const SizedBox(width: 8),
                  _deptChip('Oncology'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(s['image']!),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Department: ${s['department']}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text('Schedule'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deptChip(String dept) {
    final isSelected = dept == selectedDept;
    return ChoiceChip(
      label: Text(dept),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedDept = dept),
      selectedColor: Colors.green,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
