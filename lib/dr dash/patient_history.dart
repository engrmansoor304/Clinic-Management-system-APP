import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

// Web-only import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:url_launcher/url_launcher.dart';

/// Replace with your Dropbox access token
const String dropboxAccessToken =
    "sl.u.AGLYcDVrKHaG5v-dxaF6gJ2zwf3W6yzEl2R8DeoHkzrNdJV_KakuOl9JIcuSz_GOhRNt9xkv5M0NLvlx5YjNiD94LdlFqUYnygYbRwyTukJWaX8eWgU0_V5DQGwTOUNL7p6efCGjHR0xdL5u8Sup2o8PbOlB8Gfjt-7QqxJHGjdoTpyldSxem1fmQK-Bho6G_Rtw-svzUc43p4wWRn_XFeNmf-KpQWZXAtt3M3OS9iVwe4Xf07tDGlB2b3QU0_o4CZy12N8qFSHVge2oj6-AfcoOKSjm53C6_lJNiPbKnB_FzfTQPMRvxixODgd8cRJHmTTmkJbhsQVuq6YlnjYCayCoM93DwzUiYQELgDO_sFHRt6h_m5SWGedKUnmzhSMi6JmK1RS2ytsJpIQKqQMbiFnj7Tq-K_gJmv7ilf0RLTF2OEz0GWcSxnHvgj3lnXEEL8EOabHvwA3ENxHF0gLH7z6LKuLfnjhA8iUYilxXk-MHp-C-e93mlJQc8vCEvKxoxmjt0HXJKrQNG9cgc1MJ-L5U3Mov-zPvTh3cP8N7EaXY9S4Y851TC-mJ6t3nnJlT1HY1HlgV1HK_Awew7satZRBV9nTKkUjG4toCDA_qBdosmnqXHGeCW10QXxnbcvIs-V4QAYrJGldX4hWsOQM8yaNIJZmcwPNUduZ-jFbnkPuzp3UERLW2uQolmIPjbMlopErO13F0YPCzGWASojCbhNXe0uL9bWXVMBfw44fBUzUz4wfBmg41bBduE9R_cFxaaGOKQWfZE6XgbvmVttBwvpZIR8olxULrVjYEh6y19Baw-TBa-B-L4VMi3I7cSei3AzTpvlyDnU7LrG4L8sd00H5WaNeAPhDLuaerp1Qb83j9iMeUCx6EjKl7ulmz4axk35xfTr8xf-KxGQnhaqi0ycpgIeq4--ADC2jaJrsIHYesx37KlaECQF8pE44SIWf94aFvJgm-aPsibzZm9530vBMPh1dOenBVxH7oI6rMjnEqq6Q2hUz5ty8XQoP7ampvdlh9tYJgDwYjUPN6kXqrE4AKtZa-3OxOe2H3rr5slki2z5x-kh-mdc85m0tNLuqlrbPJwrEF9qOdaa-STHPP1rvS4reAFwRw9ykDz0DtriHpZCSzgswl3S-SI9-rhclpn9zpW0qoxavlJHJeOmpR2hYnaJNoOnqkU1hQ3sMGts5XL8oUbyd23Ko0cS-TCYqP0hmR-Sa-YEh7pbrqBj_RBwlafdEPTMxk7La9DgyCo2gNzr-MskemZNiEe8ttgEZTGx_fIG8mOWU2FLilF_hxfburtPxVwKwVBP4sSjDVA7y5azSPk4SRktXcQKYS-DnYCkh-AyjhQR7J5AU6xp8XvStdQ8lbv6gUj-uxcTltnvJO-GUho_epL0KGLJwB7C1aU_GWOtlZBWGvAxA32YGIcgq2wfhupkJUwGhYFTOo7VgPdg";

class PatientHistoryScreen extends StatefulWidget {
  final String doctorUid;

  const PatientHistoryScreen({super.key, required this.doctorUid});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  Future<void> _printPdf(Uint8List pdfBytes) async {
    if (pdfBytes.isEmpty) return;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // Must return Future<Uint8List>
        return pdfBytes;
      },
    );
  }

  Future<void> uploadPrescriptionToDropbox(
    Uint8List pdfBytes,
    String appointmentId,
    String patientName,
  ) async {
    try {
      final url = "https://content.dropboxapi.com/2/files/upload";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $dropboxAccessToken",
          "Content-Type": "application/octet-stream",
          "Dropbox-API-Arg": jsonEncode({
            "path":
                "/prescriptions/$patientName-${DateTime.now().millisecondsSinceEpoch}.pdf",
            "mode": "add",
            "autorename": true,
            "mute": false,
          }),
        },
        body: pdfBytes,
      );

      if (response.statusCode == 200) {
        final uploaded = jsonDecode(response.body);
        final dropboxPath = uploaded['path_display'];
        final pdfBase64 = base64Encode(pdfBytes);

        // Save both dropbox path and base64 to Firestore
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({'dropboxFilePath': dropboxPath, 'pdfBase64': pdfBase64});

        print("Prescription uploaded successfully!");
      } else {
        print("Dropbox upload failed: ${response.body}");
      }
    } catch (e) {
      print("Error uploading to Dropbox: $e");
    }
  }

  String searchQuery = "";
  DateTime? selectedDate;

  /// Firestore stream for completed appointments filtered by doctorUid
  Stream<QuerySnapshot> get _completedAppointmentsStream =>
      FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorUid', isEqualTo: widget.doctorUid)
          .where('status', isEqualTo: 'Completed')
          .snapshots();

  List<Map<String, dynamic>> _mapSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> patients,
  ) {
    return patients.where((p) {
      final name = (p['patient'] ?? '').toString().toLowerCase();
      final matchesName = searchQuery.isEmpty || name.contains(searchQuery);

      final matchesDate =
          selectedDate == null ||
          p['date'] ==
              "${selectedDate!.day.toString().padLeft(2, '0')}-"
                  "${selectedDate!.month.toString().padLeft(2, '0')}-"
                  "${selectedDate!.year}";

      return matchesName && matchesDate;
    }).toList();
  }

  /// Open PDF for web or mobile
  void _openPdf(Uint8List pdfBytes, String name) async {
    if (kIsWeb) {
      // Open PDF in new browser tab
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank'); // Open in new tab
      // Do NOT revoke immediately, give browser time to load
      Future.delayed(const Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(url);
      });
    } else {
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    }
  }

  /// Fetch PDF from Dropbox
  Future<Uint8List?> _fetchPdfFromDropbox(String path) async {
    try {
      final url = "https://content.dropboxapi.com/2/files/download";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $dropboxAccessToken",
          "Dropbox-API-Arg": jsonEncode({"path": path}),
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dropbox fetch failed: ${response.body}")),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching PDF: $e")));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: _buildTealGradient(),
        backgroundColor: Colors.transparent,
        title: const Text("Patient History"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _completedAppointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  final match = RegExp(
                    r'https://console.firebase.google.com[^\s]+',
                  ).firstMatch(error);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error: $error"),
                      if (match != null)
                        TextButton(
                          onPressed: () async {
                            final url = match.group(0)!;
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          child: const Text("Create required Firestore Index"),
                        ),
                    ],
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No completed appointments"));
                }

                final patients = _mapSnapshot(snapshot.data!);
                final filtered = _applyFilters(patients);

                if (filtered.isEmpty) {
                  return const Center(child: Text("No matching results"));
                }

                // Sort by createdAt descending
                filtered.sort((a, b) {
                  final t1 = a['createdAt'] as Timestamp?;
                  final t2 = b['createdAt'] as Timestamp?;
                  return (t2?.compareTo(t1 ?? Timestamp(0, 0)) ?? 0);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final formattedDate =
                        "${p['date'] ?? '-'}  ${p['time'] ?? '-'}";
                    final patientName = p['patient'] ?? '?';
                    final avatarLetter =
                        patientName.isNotEmpty ? patientName[0] : '?';

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            avatarLetter,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        title: Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: $formattedDate",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            Text("Diagnosis: ${p['diagnosis'] ?? '-'}"),
                            Text("Treatment: ${p['treatment'] ?? '-'}"),
                            Text("Medicine: ${p['medicine'] ?? '-'}"),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.picture_as_pdf, color: Colors.teal),
                                SizedBox(width: 6),
                                Text(
                                  "Options",
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.teal),
                              ],
                            ),
                          ),
                          onSelected: (value) async {
                            final dropboxPath = p['dropboxFilePath'];
                            final pdfBase64 = p['pdfBase64'];

                            final invoiceBase64 = p['invoiceBase64'];
                            final invoicePath = p['invoiceDropboxPath'];

                            Uint8List? bytes;

                            // ---------- PRESCRIPTION ----------
                            if (value == "view_pres" ||
                                value == "download_pres") {
                              if (pdfBase64 != null) {
                                bytes = base64Decode(pdfBase64);
                              } else if (dropboxPath != null) {
                                bytes = await _fetchPdfFromDropbox(dropboxPath);
                              }

                              if (bytes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No prescription available"),
                                  ),
                                );
                                return;
                              }

                              if (value == "view_pres") {
                                _openPdf(bytes, p['patient'] ?? 'Prescription');
                              } else {
                                // DOWNLOAD
                                if (kIsWeb) {
                                  final blob = html.Blob([
                                    bytes,
                                  ], 'application/pdf');
                                  final url = html.Url.createObjectUrlFromBlob(
                                    blob,
                                  );
                                  final anchor =
                                      html.AnchorElement(href: url)
                                        ..setAttribute(
                                          'download',
                                          '${p['patient']}-prescription.pdf',
                                        )
                                        ..click();
                                  html.Url.revokeObjectUrl(url);
                                } else {
                                  await Printing.layoutPdf(
                                    onLayout: (_) async => bytes!,
                                  );
                                }
                              }
                            }
                            // ---------- INVOICE ----------
                            else if (value == "view_invoice" ||
                                value == "download_invoice") {
                              if (invoiceBase64 != null) {
                                bytes = base64Decode(invoiceBase64);
                              } else if (invoicePath != null) {
                                bytes = await _fetchPdfFromDropbox(invoicePath);
                              }

                              if (bytes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No invoice available"),
                                  ),
                                );
                                return;
                              }

                              if (value == "view_invoice") {
                                _openPdf(bytes, p['patient'] ?? 'Invoice');
                              } else {
                                // DOWNLOAD
                                if (kIsWeb) {
                                  final blob = html.Blob([
                                    bytes,
                                  ], 'application/pdf');
                                  final url = html.Url.createObjectUrlFromBlob(
                                    blob,
                                  );
                                  final anchor =
                                      html.AnchorElement(href: url)
                                        ..setAttribute(
                                          'download',
                                          '${p['patient']}-invoice.pdf',
                                        )
                                        ..click();
                                  html.Url.revokeObjectUrl(url);
                                } else {
                                  await Printing.layoutPdf(
                                    onLayout: (_) async => bytes!,
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder:
                              (context) => const [
                                PopupMenuItem(
                                  value: 'view_pres',
                                  child: Text('View Prescription'),
                                ),
                                PopupMenuItem(
                                  value: 'download_pres',
                                  child: Text('Download Prescription'),
                                ),
                                PopupMenuItem(
                                  value: 'view_invoice',
                                  child: Text('View Invoice'),
                                ),
                                PopupMenuItem(
                                  value: 'download_invoice',
                                  child: Text('Download Invoice'),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTealGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search patient name...",
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged:
                  (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2026),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            icon: const Icon(Icons.date_range, color: Colors.teal),
            label: Text(
              selectedDate == null
                  ? "Filter by date"
                  : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
              style: const TextStyle(color: Colors.teal),
            ),
          ),
          if (selectedDate != null)
            IconButton(
              onPressed: () => setState(() => selectedDate = null),
              icon: const Icon(Icons.close, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }
}
