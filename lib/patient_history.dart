// patients_history_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; // For Flutter Web PDF viewing

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientsHistoryScreen extends StatefulWidget {
  const PatientsHistoryScreen({super.key});

  @override
  State<PatientsHistoryScreen> createState() => _PatientsHistoryScreenState();
}

class _PatientsHistoryScreenState extends State<PatientsHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("All Patients History"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("appointments")
                .where("status", isEqualTo: "Completed")
                .orderBy("createdAt", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(
              child: Text("No completed appointments found."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final ap = appointments[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    ap['patient'] ?? "Unknown Patient",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text("Doctor: ${ap['doctor'] ?? 'N/A'}"),
                      Text("Date: ${ap['date']}  Time: ${ap['time']}"),
                      Text("Fee: PKR ${ap['fee'] ?? '-'}"),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "prescription") {
                        _openPrescription(ap);
                      }

                      if (value == "invoice") {
                        _openInvoice(ap);
                      }
                    },

                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: "prescription",
                            child: Row(
                              children: [
                                Icon(Icons.note_alt, color: Colors.teal),
                                SizedBox(width: 8),
                                Text("View Prescription"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: "invoice",
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.indigo),
                                SizedBox(width: 8),
                                Text("View Invoice"),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // OPEN PRESCRIPTION
  void _openPrescription(Map<String, dynamic> ap) async {
    final pdfBase64 = ap['pdfBase64'];
    final dropboxUrl = ap['dropboxFileUrl'];

    // 1️⃣ If Base64 available — open directly (BEST & WORKING)
    if (pdfBase64 != null) {
      final bytes = base64Decode(pdfBase64);
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.window.open(url, "_blank");

      Future.delayed(const Duration(seconds: 10), () {
        html.Url.revokeObjectUrl(url);
      });

      return;
    }

    // 2️⃣ If Dropbox URL exists
    if (dropboxUrl != null) {
      _openPdf(dropboxUrl);
      return;
    }

    // 3️⃣ Nothing found
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Prescription not available")));
  }

  // OPEN INVOICE PDF
  // OPEN INVOICE PDF (Dropbox direct link)
  void _openInvoice(Map<String, dynamic> ap) {
    final pdfBase64 = ap['invoiceBase64'];

    if (pdfBase64 != null) {
      final bytes = base64Decode(pdfBase64);
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.window.open(url, "_blank");

      Future.delayed(const Duration(seconds: 10), () {
        html.Url.revokeObjectUrl(url);
      });

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Invoice not available")));
  }

  // GENERIC URL OPENER
  void _openPdf(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open PDF")));
    }
  }
}
