import 'package:flutter/material.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required String doctorId});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String selectedFilter = "Upcoming";
  String searchQuery = "";

  final List<Map<String, dynamic>> appointments = [
    {
      "name": "Ali Raza",
      "id": "#PAT1001",
      "number": "0312-1234567",
      "date": "2025-11-08",
      "time": "10:30 AM",
      "status": "Upcoming",
      "amount": 2500,
      "discount": 200,
      "prescription":
          "Panadol 500mg (1 tablet after meal)\nAugmentin 625mg (Twice a day)",
    },
    {
      "name": "Sara Khan",
      "id": "#PAT1002",
      "number": "0321-5566778",
      "date": "2025-11-06",
      "time": "2:00 PM",
      "status": "Completed",
      "amount": 3500,
      "discount": 0,
      "prescription": "Cough syrup (10ml morning & night)\nVitamin C daily",
    },
    {
      "name": "Ahmed Iqbal",
      "id": "#PAT1003",
      "number": "0308-9876543",
      "date": "2025-11-07",
      "time": "5:00 PM",
      "status": "Pending",
      "amount": 2000,
      "discount": 100,
      "prescription": "Paracetamol 500mg (Twice daily)\nORS for hydration",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        appointments
            .where(
              (a) =>
                  a['status'] == selectedFilter &&
                  a['name'].toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

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
          // Header with Filter + Search
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
          const SizedBox(height: 16),

          // Search bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              hintText: "Search by patient name...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),

          const SizedBox(height: 20),
          Expanded(
            child:
                filtered.isEmpty
                    ? const Center(
                      child: Text(
                        "No appointments found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final a = filtered[i];
                        return _appointmentCard(context, a);
                      },
                    ),
          ),
        ],
      ),
    );
  }

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
          DropdownMenuItem(value: "Upcoming", child: Text("Upcoming")),
          DropdownMenuItem(value: "Completed", child: Text("Completed")),
          DropdownMenuItem(value: "Pending", child: Text("Pending")),
        ],
        onChanged: (value) {
          setState(() => selectedFilter = value!);
        },
      ),
    );
  }

  Widget _appointmentCard(BuildContext context, Map<String, dynamic> a) {
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
                        a['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        a['id'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(a['status']),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📅 ${a['date']}  ⏰ ${a['time']}"),
                Text(
                  "💸 PKR ${a['amount']}",
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
                _smallButton(
                  "Prescription",
                  Icons.description,
                  Colors.indigo,
                  () => _showPrescriptionDialog(context, a),
                ),
                const SizedBox(width: 10),
                _smallButton(
                  "Invoice",
                  Icons.receipt_long,
                  Colors.teal,
                  () => _showInvoiceDialog(context, a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  // ====== PRESCRIPTION POPUP ======
  void _showPrescriptionDialog(BuildContext context, Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Prescription Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient: ${a['name']} (${a['id']})"),
                Text("Contact: ${a['number']}"),
                const Divider(),
                Text(a['prescription']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  // ====== INVOICE POPUP ======
  void _showInvoiceDialog(BuildContext context, Map<String, dynamic> a) {
    final total = a['amount'] - a['discount'];
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Billing Invoice"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient: ${a['name']} (${a['id']})"),
                Text("Contact: ${a['number']}"),
                const SizedBox(height: 10),
                Text("Appointment Date: ${a['date']}"),
                Text("Time: ${a['time']}"),
                const Divider(height: 20),
                Text("Consultation Fee: PKR ${a['amount']}"),
                Text("Discount: PKR ${a['discount']}"),
                const Divider(),
                Text(
                  "Total Payable: PKR $total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: Add print logic here later
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Printing invoice...")),
                  );
                },
                child: const Text(
                  "Print",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }
}
