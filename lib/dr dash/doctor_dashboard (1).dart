import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'video_consultation.dart';
import 'patient_history.dart';
import 'doctor_payment_screen.dart';
import 'appointments_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int selectedIndex = 0;
  bool isMenuOpen = true;

  bool showProfileMenu = false;
  bool showNotificationPopup = false;
  bool showSettingsPanel = false;

  final currentUser = FirebaseAuth.instance.currentUser;

  // Doctor stats
  int totalAppointments = 0;
  int totalPatients = 0;
  int pendingAppointments = 0;
  double totalEarnings = 0;

  Map<String, dynamic>? doctorProfile;

  // Monthly earnings for graph
  List<double> monthlyEarnings = List.generate(12, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _loadDoctorStats();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorStats() async {
    if (currentUser == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorUid', isEqualTo: currentUser!.uid)
            .get();

    int total = snapshot.docs.length;
    int pending = 0;
    double earnings = 0;
    Set<String> patients = {};
    List<double> tempMonthly = List.generate(12, (_) => 0.0);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status']?.toString() ?? '').toLowerCase();

      if (status == 'pending') pending++;

      if (status == 'completed') {
        double amt = 0;
        if (data['amount'] != null) {
          amt =
              (data['amount'] is num)
                  ? (data['amount'] as num).toDouble()
                  : double.tryParse(data['amount'].toString()) ?? 0;
        }
        earnings += amt;

        if (data['createdAt'] != null) {
          try {
            final date = (data['createdAt'] as Timestamp).toDate();
            tempMonthly[date.month - 1] += amt;
          } catch (_) {}
        }

        final patientId = data['patientUid'] ?? data['patient'];
        if (patientId != null) patients.add(patientId.toString());
      }
    }

    setState(() {
      totalAppointments = total;
      pendingAppointments = pending;
      totalPatients = patients.length;
      totalEarnings = earnings;
      monthlyEarnings = tempMonthly;
    });
  }

  Future<void> _loadDoctorProfile() async {
    if (currentUser == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(currentUser!.uid)
            .get();

    if (doc.exists) {
      setState(() {
        doctorProfile = doc.data();
      });
    }
  }

  final List<Map<String, dynamic>> menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.calendar_month, 'label': 'Appointments'},
    {'icon': Icons.video_call, 'label': 'Online Appointments'},
    {'icon': Icons.history, 'label': 'Patient History'},
    {'icon': Icons.attach_money, 'label': 'Doctor Payment'},
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;
    double sidebarWidth = isMobile ? (isMenuOpen ? 200 : 60) : 250;

    final List<Widget> screens = [
      dashboardScreen(),
      const DrAppointments(),
      VideoConsultationScreen(doctorUid: currentUser!.uid),
      PatientHistoryScreen(doctorUid: currentUser!.uid),
      DoctorPaymentsScreen(doctorUid: currentUser!.uid),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sidebarWidth,
                child: sidebarMenu(isMobile),
              ),
              Expanded(
                child: Column(
                  children: [topBar(), Expanded(child: screens[selectedIndex])],
                ),
              ),
            ],
          ),
          if (showProfileMenu) profileDropdown(),
          if (showNotificationPopup) notificationPopup(),
          if (showSettingsPanel) settingsPanel(),
        ],
      ),
    );
  }

  // ---------------- TOP BAR -------------------------
  Widget topBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => isMenuOpen = !isMenuOpen),
          ),
          const SizedBox(width: 10),
          const Text(
            "Doctor Portal",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.teal),
            onPressed: () {
              setState(() {
                showNotificationPopup = !showNotificationPopup;
                showProfileMenu = false;
              });
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                showProfileMenu = !showProfileMenu;
                showNotificationPopup = false;
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.teal,
              backgroundImage:
                  doctorProfile?['profileImage'] != null
                      ? NetworkImage(doctorProfile!['profileImage'])
                      : null,
              child:
                  doctorProfile?['profileImage'] == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SIDEBAR MENU -------------------------
  Widget sidebarMenu(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          if (!isMobile || isMenuOpen)
            Text(
              doctorProfile?['name'] ??
                  currentUser?.displayName ??
                  "Doctor Name",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      menuItems[index]['icon'],
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    title:
                        isMenuOpen
                            ? Text(
                              menuItems[index]['label'],
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight:
                                    selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            )
                            : null,
                    tileColor: selected ? Colors.teal.withOpacity(0.2) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        if (isMobile) isMenuOpen = false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.3)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pending: $pendingAppointments",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DASHBOARD SCREEN -------------------------
  Widget dashboardScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard Overview",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                Icons.calendar_today,
                "Appointments",
                "$totalAppointments",
                Colors.teal,
              ),
              _statCard(
                Icons.people_alt,
                "Patients",
                "$totalPatients",
                Colors.indigo,
              ),
              _statCard(
                Icons.attach_money,
                "Earnings",
                "PKR ${totalEarnings.toStringAsFixed(0)}",
                Colors.blue,
              ),
              _subscribeCard(),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Performance Summary",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _progressIndicator("Consultations", 0.75, Colors.teal),
                    _progressIndicator("Follow-ups", 0.60, Colors.indigo),
                    _progressIndicator("Feedbacks", 0.85, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Revenue Graph",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          earningsChart(),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _subscribeCard() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.tealAccent],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, color: Colors.white, size: 28),
          SizedBox(height: 12),
          Text(
            "Instant Alerts",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Stay updated with all patient updates instantly.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _progressIndicator(String label, double percent, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent,
                strokeWidth: 8,
                color: color,
                backgroundColor: color.withOpacity(0.2),
              ),
              Center(
                child: Text(
                  "${(percent * 100).toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget earningsChart() {
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < monthlyEarnings.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyEarnings[i],
              width: 18,
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: 20000,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.teal,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: 35000,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.teal,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("Jan");
                    case 1:
                      return const Text("Feb");
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "PKR ${rod.toY.toInt()}",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PROFILE, NOTIFICATION, SETTINGS ----------------
  Widget profileDropdown() {
    return Positioned(
      right: 20,
      top: 70,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  setState(() {
                    showSettingsPanel = true;
                    showProfileMenu = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget notificationPopup() {
    return Positioned(
      right: 60,
      top: 70,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text("No new notifications"),
        ),
      ),
    );
  }

  Widget settingsPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 350,
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => showSettingsPanel = false),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Profile Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.teal,
                backgroundImage:
                    doctorProfile?['profileImage'] != null
                        ? NetworkImage(doctorProfile!['profileImage'])
                        : null,
                child:
                    doctorProfile?['profileImage'] == null
                        ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            settingsField("Name", doctorProfile?['name'] ?? "Doctor Name"),
            settingsField(
              "Email",
              doctorProfile?['email'] ?? "Email Not Found",
            ),
            settingsField(
              "Specialization",
              doctorProfile?['specialization'] ?? "Not Added",
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  "Update Profile",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget settingsField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
