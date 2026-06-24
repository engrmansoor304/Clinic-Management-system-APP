// invoice_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  final String appointmentId;

  const InvoiceScreen({
    super.key,
    required this.appointmentData,
    required this.appointmentId,
  });

  // ------------------ Save to Firestore ------------------
  Future<void> _saveToFirebase(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(appointmentId)
          .set({
            'appointmentData': appointmentData,
            'timestamp': FieldValue.serverTimestamp(),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice saved to Firebase!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving to Firebase: $e")));
    }
  }

  // ------------------ Upload to Dropbox ------------------
  Future<void> _uploadToDropbox(BuildContext context) async {
    try {
      final pdfBytes = await _generatePdf();

      final token =
          "sl.u.AGLYcDVrKHaG5v-dxaF6gJ2zwf3W6yzEl2R8DeoHkzrNdJV_KakuOl9JIcuSz_GOhRNt9xkv5M0NLvlx5YjNiD94LdlFqUYnygYbRwyTukJWaX8eWgU0_V5DQGwTOUNL7p6efCGjHR0xdL5u8Sup2o8PbOlB8Gfjt-7QqxJHGjdoTpyldSxem1fmQK-Bho6G_Rtw-svzUc43p4wWRn_XFeNmf-KpQWZXAtt3M3OS9iVwe4Xf07tDGlB2b3QU0_o4CZy12N8qFSHVge2oj6-AfcoOKSjm53C6_lJNiPbKnB_FzfTQPMRvxixODgd8cRJHmTTmkJbhsQVuq6YlnjYCayCoM93DwzUiYQELgDO_sFHRt6h_m5SWGedKUnmzhSMi6JmK1RS2ytsJpIQKqQMbiFnj7Tq-K_gJmv7ilf0RLTF2OEz0GWcSxnHvgj3lnXEEL8EOabHvwA3ENxHF0gLH7z6LKuLfnjhA8iUYilxXk-MHp-C-e93mlJQc8vCEvKxoxmjt0HXJKrQNG9cgc1MJ-L5U3Mov-zPvTh3cP8N7EaXY9S4Y851TC-mJ6t3nnJlT1HY1HlgV1HK_Awew7satZRBV9nTKkUjG4toCDA_qBdosmnqXHGeCW10QXxnbcvIs-V4QAYrJGldX4hWsOQM8yaNIJZmcwPNUduZ-jFbnkPuzp3UERLW2uQolmIPjbMlopErO13F0YPCzGWASojCbhNXe0uL9bWXVMBfw44fBUzUz4wfBmg41bBduE9R_cFxaaGOKQWfZE6XgbvmVttBwvpZIR8olxULrVjYEh6y19Baw-TBa-B-L4VMi3I7cSei3AzTpvlyDnU7LrG4L8sd00H5WaNeAPhDLuaerp1Qb83j9iMeUCx6EjKl7ulmz4axk35xfTr8xf-KxGQnhaqi0ycpgIeq4--ADC2jaJrsIHYesx37KlaECQF8pE44SIWf94aFvJgm-aPsibzZm9530vBMPh1dOenBVxH7oI6rMjnEqq6Q2hUz5ty8XQoP7ampvdlh9tYJgDwYjUPN6kXqrE4AKtZa-3OxOe2H3rr5slki2z5x-kh-mdc85m0tNLuqlrbPJwrEF9qOdaa-STHPP1rvS4reAFwRw9ykDz0DtriHpZCSzgswl3S-SI9-rhclpn9zpW0qoxavlJHJeOmpR2hYnaJNoOnqkU1hQ3sMGts5XL8oUbyd23Ko0cS-TCYqP0hmR-Sa-YEh7pbrqBj_RBwlafdEPTMxk7La9DgyCo2gNzr-MskemZNiEe8ttgEZTGx_fIG8mOWU2FLilF_hxfburtPxVwKwVBP4sSjDVA7y5azSPk4SRktXcQKYS-DnYCkh-AyjhQR7J5AU6xp8XvStdQ8lbv6gUj-uxcTltnvJO-GUho_epL0KGLJwB7C1aU_GWOtlZBWGvAxA32YGIcgq2wfhupkJUwGhYFTOo7VgPdg";

      final path =
          "/Invoices/invoice-$appointmentId.pdf"; // <-- now uploading PDF

      final response = await http.post(
        Uri.parse("https://content.dropboxapi.com/2/files/upload"),
        headers: {
          "Authorization": "Bearer $token",
          "Dropbox-API-Arg": jsonEncode({
            "path": path,
            "mode": "overwrite",
            "autorename": true,
            "mute": false,
          }),
          "Content-Type": "application/octet-stream",
        },
        body: pdfBytes, // <-- UPLOADING REAL PDF
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final dropboxPath = result['path_display'];

        // Also save to Firestore
        await FirebaseFirestore.instance
            .collection("appointments")
            .doc(appointmentId)
            .update({
              "invoiceDropboxPath": dropboxPath,
              "invoiceBase64": base64Encode(pdfBytes),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice uploaded successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dropbox upload failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final patientName = appointmentData['patient'] ?? 'N/A';
    final age = appointmentData['age'] ?? '-';
    final gender = appointmentData['gender'] ?? 'Unknown';
    final cnic = appointmentData['cnic'] ?? '-';
    final date = appointmentData['date'] ?? '';
    final time = appointmentData['time'] ?? '';
    final amount = appointmentData['fee'] ?? 0;
    final List<dynamic> servicesFromDb = appointmentData['services'] ?? [];
    final services =
        servicesFromDb.isNotEmpty ? servicesFromDb : ["Consultation Fee"];
    final paid = appointmentData['paid'] ?? false;

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "The clinic portal",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Invoice",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Text("Patient: $patientName"),
                pw.Text("Age: $age   Gender: $gender"),
                pw.Text("CNIC: $cnic"),
                pw.Text("Date: $date   Time: $time"),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Services:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                ...services.map((s) => pw.Text("• $s")),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Total Amount: PKR $amount",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Text("Payment Status: ${paid ? "Paid" : "Pending"}"),
              ],
            ),
      ),
    );

    return pdf.save();
  }

  // ------------------ Print / Download PDF ------------------
  Future<void> _printInvoice() async {
    final pdf = pw.Document();

    final patientName = appointmentData['patient'] ?? 'N/A';
    final age = appointmentData['age'] ?? '-';
    final gender = appointmentData['gender'] ?? 'Unknown';
    final cnic = appointmentData['cnic'] ?? '-';
    final date = appointmentData['date'] ?? '';
    final time = appointmentData['time'] ?? '';
    final amount = appointmentData['fee'] ?? 0;
    final List<dynamic> servicesFromDb = appointmentData['services'] ?? [];
    final services =
        servicesFromDb.isNotEmpty ? servicesFromDb : ["Consultation Fee"];
    final paid = appointmentData['paid'] ?? false;

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "The clinic portal",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Invoice",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Text("Patient: $patientName"),
                pw.Text("Age: $age   Gender: $gender"),
                pw.Text("CNIC: $cnic"),
                pw.Text("Date: $date   Time: $time"),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Services:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                ...services.map((s) => pw.Text("• $s")),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Total Amount: PKR $amount",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text("Payment Status: ${paid ? "Paid ✅" : "Pending ❌"}"),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Some text",
                  style: pw.TextStyle(color: PdfColors.amber),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final patientName = appointmentData['patient'] ?? 'N/A';
    final age = appointmentData['age'] ?? '-';
    final gender = appointmentData['gender'] ?? 'Unknown';
    final cnic = appointmentData['cnic'] ?? '-';
    final date = appointmentData['date'] ?? '';
    final time = appointmentData['time'] ?? '';
    final amount = appointmentData['fee'] ?? 0;
    final List<dynamic> servicesFromDb = appointmentData['services'] ?? [];
    final services =
        servicesFromDb.isNotEmpty ? servicesFromDb : ["Consultation Fee"];
    final paid = appointmentData['paid'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("E‑Mareez Clinic Invoice"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "E‑Mareez Clinic",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Invoice",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const Divider(),
                  Text("Patient: $patientName"),
                  Text("Age: $age   Gender: $gender"),
                  Text("CNIC: $cnic"),
                  const SizedBox(height: 10),
                  Text("Date: $date   Time: $time"),
                  const SizedBox(height: 20),
                  const Text(
                    "Services:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...services.map((s) => Text("• $s")).toList(),
                  const SizedBox(height: 10),
                  Text(
                    "Total Amount: PKR $amount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Payment Status: ${paid ? "Paid ✅" : "Pending ❌"}",
                    style: TextStyle(
                      color: paid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Thank you for your trust!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text("Print / Download"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _printInvoice,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Upload to Dropbox"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  onPressed: () => _uploadToDropbox(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save to Firebase"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _saveToFirebase(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
