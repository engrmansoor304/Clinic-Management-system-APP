// ------------------------------
// SAFE IMPORTS (Mobile + Web)
// ------------------------------
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Web-only import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ------------------------------
// Dropbox Access Token
// ------------------------------
const String dropboxAccessToken =
    "sl.u.AGLYcDVrKHaG5v-dxaF6gJ2zwf3W6yzEl2R8DeoHkzrNdJV_KakuOl9JIcuSz_GOhRNt9xkv5M0NLvlx5YjNiD94LdlFqUYnygYbRwyTukJWaX8eWgU0_V5DQGwTOUNL7p6efCGjHR0xdL5u8Sup2o8PbOlB8Gfjt-7QqxJHGjdoTpyldSxem1fmQK-Bho6G_Rtw-svzUc43p4wWRn_XFeNmf-KpQWZXAtt3M3OS9iVwe4Xf07tDGlB2b3QU0_o4CZy12N8qFSHVge2oj6-AfcoOKSjm53C6_lJNiPbKnB_FzfTQPMRvxixODgd8cRJHmTTmkJbhsQVuq6YlnjYCayCoM93DwzUiYQELgDO_sFHRt6h_m5SWGedKUnmzhSMi6JmK1RS2ytsJpIQKqQMbiFnj7Tq-K_gJmv7ilf0RLTF2OEz0GWcSxnHvgj3lnXEEL8EOabHvwA3ENxHF0gLH7z6LKuLfnjhA8iUYilxXk-MHp-C-e93mlJQc8vCEvKxoxmjt0HXJKrQNG9cgc1MJ-L5U3Mov-zPvTh3cP8N7EaXY9S4Y851TC-mJ6t3nnJlT1HY1HlgV1HK_Awew7satZRBV9nTKkUjG4toCDA_qBdosmnqXHGeCW10QXxnbcvIs-V4QAYrJGldX4hWsOQM8yaNIJZmcwPNUduZ-jFbnkPuzp3UERLW2uQolmIPjbMlopErO13F0YPCzGWASojCbhNXe0uL9bWXVMBfw44fBUzUz4wfBmg41bBduE9R_cFxaaGOKQWfZE6XgbvmVttBwvpZIR8olxULrVjYEh6y19Baw-TBa-B-L4VMi3I7cSei3AzTpvlyDnU7LrG4L8sd00H5WaNeAPhDLuaerp1Qb83j9iMeUCx6EjKl7ulmz4axk35xfTr8xf-KxGQnhaqi0ycpgIeq4--ADC2jaJrsIHYesx37KlaECQF8pE44SIWf94aFvJgm-aPsibzZm9530vBMPh1dOenBVxH7oI6rMjnEqq6Q2hUz5ty8XQoP7ampvdlh9tYJgDwYjUPN6kXqrE4AKtZa-3OxOe2H3rr5slki2z5x-kh-mdc85m0tNLuqlrbPJwrEF9qOdaa-STHPP1rvS4reAFwRw9ykDz0DtriHpZCSzgswl3S-SI9-rhclpn9zpW0qoxavlJHJeOmpR2hYnaJNoOnqkU1hQ3sMGts5XL8oUbyd23Ko0cS-TCYqP0hmR-Sa-YEh7pbrqBj_RBwlafdEPTMxk7La9DgyCo2gNzr-MskemZNiEe8ttgEZTGx_fIG8mOWU2FLilF_hxfburtPxVwKwVBP4sSjDVA7y5azSPk4SRktXcQKYS-DnYCkh-AyjhQR7J5AU6xp8XvStdQ8lbv6gUj-uxcTltnvJO-GUho_epL0KGLJwB7C1aU_GWOtlZBWGvAxA32YGIcgq2wfhupkJUwGhYFTOo7VgPdg";

// ------------------------------
// Prescription Screen
// ------------------------------
class PrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentData;
  final String appointmentId;
  final Map<String, dynamic> patientData;

  PrescriptionScreen({
    super.key,
    required this.appointmentData,
    required this.appointmentId,
    required Map<String, dynamic> patientData,
  }) : patientData = {
         'patient': appointmentData['patient'] ?? 'N/A',
         'age': appointmentData['age'] ?? '-',
         'gender': appointmentData['gender'] ?? 'Unknown',
         'cnic': appointmentData['cnic'] ?? '-',
       };

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  // Controllers
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Medicine list
  List<Map<String, String>> medicines = [];

  // Defaults
  String dosage = "1-0-1";
  String duration = "3 Days";
  DateTime followUpDate = DateTime.now().add(const Duration(days: 7));
  bool isEnglish = true;
  bool _isUploading = false;

  // Autocomplete data
  final List<String> allMedicines = [
    "Paracetamol",
    "Amoxicillin",
    "Ibuprofen",
    "Cefixime",
    "Azithromycin",
    "Vitamin D",
    "Metformin",
    "Insulin",
    "Omeprazole",
    "Cough Syrup",
    "Antihistamine",
  ];

  // ------------------------------
  // PDF Generation
  // ------------------------------
  Future<Uint8List?> _buildPdfBytes() async {
    if (diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty ||
        medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return null;
    }

    final pdf = pw.Document();
    final patient = widget.patientData;
    final name = patient['patient'] ?? 'N/A';
    final cnic = patient['cnic'] ?? '-';
    final gender = patient['gender'] ?? 'Unknown';
    final age = patient['age'] ?? '-';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "The Clinic Portal",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.Divider(height: 20, thickness: 2),
                pw.Text(
                  "Patient Info",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text("Name: $name"),
                pw.Text("Age: $age"),
                pw.Text("Gender: $gender"),
                pw.Text("CNIC: $cnic"),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Diagnosis",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.Text(diagnosisController.text),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Treatment / Advice",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.Text(treatmentController.text),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Medicines",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.Table.fromTextArray(
                  headers: ["Medicine", "Dosage", "Duration", "Notes"],
                  data:
                      medicines
                          .map(
                            (m) => [
                              m['name'],
                              m['dosage'],
                              m['duration'],
                              m['notes'] ?? '-',
                            ],
                          )
                          .toList(),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  "Follow-up Date: ${followUpDate.day}-${followUpDate.month}-${followUpDate.year}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
      ),
    );

    return await pdf.save();
  }

  Future<void> _generatePDF() async {
    final pdfBytes = await _buildPdfBytes();
    if (pdfBytes == null) return;

    final patient = widget.patientData;
    final name = (patient['patient'] ?? 'patient').toString().replaceAll(
      ' ',
      '_',
    );

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', 'Prescription_$name.pdf')
            ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Prescription_$name.pdf',
      );
    }
  }

  // ------------------------------
  // Dropbox Upload
  // ------------------------------
  Future<void> _uploadToDropbox() async {
    if (diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty ||
        medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    if (dropboxAccessToken.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Dropbox token missing")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final pdfBytes = await _buildPdfBytes();
      if (pdfBytes == null) return;

      final patient = widget.patientData;
      final name = (patient['patient'] ?? 'patient').toString().replaceAll(
        ' ',
        '_',
      );
      final filename = "/Prescription_${name}_${widget.appointmentId}.pdf";

      final response = await http.post(
        Uri.parse("https://content.dropboxapi.com/2/files/upload"),
        headers: {
          "Authorization": "Bearer $dropboxAccessToken",
          "Content-Type": "application/octet-stream",
          "Dropbox-API-Arg": jsonEncode({
            "path": filename,
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

        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update({
              'dropboxFilePath': dropboxPath,
              'pdfBase64': base64Encode(pdfBytes),
              'diagnosis': diagnosisController.text,
              'treatment': treatmentController.text,
              'medicines': medicines,
              'followUpDate': followUpDate.toIso8601String(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Uploaded to Dropbox: $filename")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dropbox upload failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ------------------------------
  // Save to Firestore
  // ------------------------------
  Future<void> _saveToFirestore() async {
    if (diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty ||
        medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("prescriptions")
          .doc(widget.appointmentId)
          .set({
            "patient": widget.patientData['patient'],
            "age": widget.patientData['age'],
            "gender": widget.patientData['gender'],
            "cnic": widget.patientData['cnic'],
            "diagnosis": diagnosisController.text,
            "treatment": treatmentController.text,
            "medicines": medicines,
            "followUpDate": followUpDate.toIso8601String(),
            "createdAt": DateTime.now().toIso8601String(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ------------------------------
  // Add Medicine
  // ------------------------------
  void _addMedicine() {
    final name = medicineNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish ? "Enter medicine name" : "دوائی کا نام درج کریں",
          ),
        ),
      );
      return;
    }

    setState(() {
      medicines.add({
        "name": name,
        "dosage": dosage,
        "duration": duration,
        "notes": notesController.text.trim(),
      });

      medicineNameController.clear();
      notesController.clear();
      dosage = "1-0-1";
      duration = "3 Days";
    });
  }

  // ------------------------------
  // Pick Follow-Up Date
  // ------------------------------
  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: followUpDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => followUpDate = picked);
  }

  // ------------------------------
  // Autocomplete Field
  // ------------------------------
  Widget _medicineAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (text) {
        if (text.text.isEmpty) return const Iterable<String>.empty();
        return allMedicines.where(
          (med) => med.toLowerCase().contains(text.text.toLowerCase()),
        );
      },
      onSelected: (value) => medicineNameController.text = value,
      fieldViewBuilder: (context, controller, node, onComplete) {
        return TextField(
          controller: controller,
          focusNode: node,
          decoration: const InputDecoration(
            labelText: "Medicine Name",
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  // ------------------------------
  // UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? "Patient Prescription" : "نسخہ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isEnglish = !isEnglish),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: "Diagnosis",
              child: TextField(
                controller: diagnosisController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            _buildCard(
              title: "Treatment / Advice",
              child: TextField(
                controller: treatmentController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            _buildCard(
              title: "Medicines",
              child: Column(
                children: [
                  _medicineAutocomplete(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          value: dosage,
                          items:
                              ["1-0-1", "1-1-1", "0-1-1"]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => dosage = v!),
                          decoration: const InputDecoration(
                            labelText: "Dosage",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField(
                          value: duration,
                          items:
                              ["3 Days", "5 Days", "7 Days"]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => duration = v!),
                          decoration: const InputDecoration(
                            labelText: "Duration",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Medicine"),
                  ),
                  if (medicines.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final med = medicines[index];
                        return ListTile(
                          title: Text("${med['name']} (${med['dosage']})"),
                          subtitle: Text(med['notes'] ?? ""),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => medicines.removeAt(index));
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            _buildCard(
              title: "Follow-Up Date",
              child: Row(
                children: [
                  Text(
                    "${followUpDate.day}-${followUpDate.month}-${followUpDate.year}",
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickFollowUpDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveToFirestore,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Generate PDF"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadToDropbox,
                icon:
                    _isUploading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading ? "Uploading..." : "Upload to Dropbox",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
