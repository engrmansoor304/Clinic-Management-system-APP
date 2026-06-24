import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DoctorPaymentsScreen extends StatefulWidget {
  final String doctorUid;
  const DoctorPaymentsScreen({super.key, required this.doctorUid});

  @override
  State<DoctorPaymentsScreen> createState() => _DoctorPaymentsScreenState();
}

class _DoctorPaymentsScreenState extends State<DoctorPaymentsScreen> {
  bool useDateRange = false;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);

  List<Map<String, dynamic>> _payments = [];
  double _doctorFee = 2000; // fallback

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFmt = DateFormat('dd/MM/yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    _fetchDoctorFeeAndPayments();
  }

  // ------------------- CSV Export -------------------
  Future<void> _exportCSV() async {
    if (_filteredPayments.isEmpty) return;

    List<List<String>> rows = [
      [
        "Appointment Id",
        "Info",
        "Patient Name",
        "Phone",
        "Amount",
        "Date",
        "Status",
      ],
    ];

    for (var p in _filteredPayments) {
      rows.add([
        p['id'].toString(),
        p['info'].toString(),
        p['patient'].toString(),
        p['phone'].toString(),
        p['amount'].toString(),
        _dateTimeFmt.format(p['date']),
        p['notes'].toString(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getTemporaryDirectory(); // temp storage
      final path = "${directory.path}/doctor_payments.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // Share the CSV file
      await Share.shareXFiles([XFile(path)], text: "Doctor Payments CSV");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("CSV ready to share!")));
    } catch (e) {
      debugPrint("CSV export error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV export failed: $e")));
    }
  }

  // ------------------- PDF Export -------------------
  Future<void> _exportPDF() async {
    if (_filteredPayments.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No payments to export!")));
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              children: [
                pw.Text("Doctor Payments", style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: [
                    "Appointment Id",
                    "Info",
                    "Patient",
                    "Phone",
                    "Amount",
                    "Date",
                    "Status",
                  ],
                  data:
                      _filteredPayments
                          .map(
                            (p) => [
                              p['id'].toString(),
                              p['info'].toString(),
                              p['patient'].toString(),
                              p['phone'].toString(),
                              p['amount'].toString(),
                              _dateTimeFmt.format(p['date']),
                              p['notes'].toString(),
                            ],
                          )
                          .toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF ready for printing!")));
  }

  // ------------------- Fetch Data -------------------
  Future<void> _fetchDoctorFeeAndPayments() async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(widget.doctorUid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        if (data['fee'] != null) {
          _doctorFee = double.tryParse(data['fee'].toString()) ?? 2000;
        }
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorUid', isEqualTo: widget.doctorUid)
              .get();

      final data =
          snapshot.docs.map((doc) {
            final d = doc.data();
            double amount = double.tryParse(d['fee'] ?? '2000') ?? 2000;

            DateTime dateTime;
            try {
              final dateParts = d['date'].split('-');
              final timeStr = d['time'] ?? '12:00 PM';
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final year = int.parse(dateParts[2]);
              dateTime = DateFormat.jm().parse(timeStr);
              dateTime = DateTime(
                year,
                month,
                day,
                dateTime.hour,
                dateTime.minute,
              );
            } catch (e) {
              dateTime = DateTime.now();
            }

            return {
              "id": doc.id,
              "info": d['appointmentType'] ?? 'N/A',
              "patient": d['patient'] ?? 'Unknown',
              "phone": d['phone'] ?? 'N/A',
              "amount": amount,
              "date": dateTime,
              "notes": d['status'] ?? 'No notes',
            };
          }).toList();

      setState(() => _payments = data);
    } catch (e) {
      debugPrint("Error fetching payments: $e");
    }
  }

  // ------------------- Filtered Payments -------------------
  List<Map<String, dynamic>> get _filteredPayments {
    DateTime from = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    DateTime to = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    return _payments.where((p) {
        final DateTime d = p['date'] as DateTime;
        return !d.isBefore(from) && !d.isAfter(to);
      }).toList()
      ..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
  }

  double get totalSales =>
      _filteredPayments.fold(0.0, (sum, p) => sum + (p['amount'] as double));
  double get doctorRevenue => totalSales * 0.9;
  int get totalPatients =>
      _filteredPayments.map((p) => p['patient'] as String).toSet().length;
  int get totalAppointments => _filteredPayments.length;

  // ------------------- Date/Time Pickers -------------------
  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (picked != null) setState(() => startTime = picked);
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: endTime);
    if (picked != null) setState(() => endTime = picked);
  }

  // ------------------- Payment Details -------------------
  void _showPaymentDetails(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Payment - ${p['id']}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient: ${p['patient']}"),
                Text("Phone: ${p['phone']}"),
                Text("Info: ${p['info']}"),
                Text("Amount: Rs ${p['amount'].toStringAsFixed(0)}"),
                Text("Date: ${_dateTimeFmt.format(p['date'])}"),
                Text("Notes: ${p['notes']}"),
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

  // ------------------- Build UI -------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Doctor Payments"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF009688), Color(0xFF26A69A)],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            onSelected: (value) {
              if (value == 'csv') {
                _exportCSV();
              } else if (value == 'pdf') {
                _exportPDF();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'csv', child: Text("Export CSV")),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Text("Export PDF / Print"),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterCard(isWide),
            const SizedBox(height: 16),
            _buildStatCards(isWide),
            const SizedBox(height: 16),
            _buildTableCard(isWide),
          ],
        ),
      ),
    );
  }

  // ---------------- UI WIDGETS ----------------
  Widget _buildFilterCard(bool isWide) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: useDateRange,
                  onChanged: (v) => setState(() => useDateRange = v!),
                ),
                const Text("Select Date"),
                Radio<bool>(
                  value: true,
                  groupValue: useDateRange,
                  onChanged: (v) => setState(() => useDateRange = v!),
                ),
                const Text("Select Date Range"),
                IconButton(
                  onPressed: () {
                    setState(() {
                      useDateRange = false;
                      startDate = DateTime.now();
                      endDate = DateTime.now();
                      startTime = const TimeOfDay(hour: 0, minute: 0);
                      endTime = const TimeOfDay(hour: 23, minute: 59);
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 700;
                if (wide) {
                  return Row(
                    children: [
                      _dateField(
                        "Start Date",
                        _dateFmt.format(startDate),
                        () => _pickStartDate(context),
                      ),
                      if (useDateRange)
                        _dateField(
                          "End Date",
                          _dateFmt.format(endDate),
                          () => _pickEndDate(context),
                        ),
                      _timeField(
                        "Start Time",
                        startTime.format(context),
                        () => _pickStartTime(context),
                      ),
                      _timeField(
                        "End Time",
                        endTime.format(context),
                        () => _pickEndTime(context),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.search),
                        label: const Text("Filter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _dateField(
                        "Start Date",
                        _dateFmt.format(startDate),
                        () => _pickStartDate(context),
                      ),
                      if (useDateRange)
                        _dateField(
                          "End Date",
                          _dateFmt.format(endDate),
                          () => _pickEndDate(context),
                        ),
                      _timeField(
                        "Start Time",
                        startTime.format(context),
                        () => _pickStartTime(context),
                      ),
                      _timeField(
                        "End Time",
                        endTime.format(context),
                        () => _pickEndTime(context),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.search),
                        label: const Text("Filter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _timeField(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.access_time, color: Colors.teal),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _buildStatCards(bool isWide) {
    final cards = [
      _statCard(
        "Total Sales",
        "Rs ${totalSales.toStringAsFixed(0)}",
        Colors.blue,
        Colors.lightBlue,
      ),
      _statCard(
        "Doctor Revenue",
        "Rs ${doctorRevenue.toStringAsFixed(0)}",
        Colors.cyan,
        Colors.teal,
      ),
      _statCard(
        "Total Patients",
        "$totalPatients",
        Colors.green,
        Colors.lightGreen,
      ),
      _statCard(
        "Total Appointments",
        "$totalAppointments",
        Colors.purple,
        Colors.deepPurple,
      ),
    ];

    if (isWide) {
      return Row(
        children:
            cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: c,
                    ),
                  ),
                )
                .toList(),
      );
    } else {
      return Column(
        children:
            cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: c,
                  ),
                )
                .toList(),
      );
    }
  }

  Widget _statCard(String title, String value, Color start, Color end) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end]),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: const Icon(Icons.monetization_on, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(bool isWide) {
    final data = _filteredPayments;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Payments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Appointment Id')),
                  DataColumn(label: Text('Info')),
                  DataColumn(label: Text('Patient Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows:
                    data
                        .map(
                          (p) => DataRow(
                            cells: [
                              DataCell(Text(p['id'])),
                              DataCell(Text(p['info'])),
                              DataCell(Text(p['patient'])),
                              DataCell(Text(p['phone'])),
                              DataCell(
                                Text("Rs ${p['amount'].toStringAsFixed(0)}"),
                              ),
                              DataCell(Text(_dateTimeFmt.format(p['date']))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () => _showPaymentDetails(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.print,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Print / PDF coming soon',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
            if (data.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "No payments found!",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
