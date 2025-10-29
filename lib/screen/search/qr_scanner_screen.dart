import 'package:cs261_project/screen/profile/alumni_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cs261_project/profile/alumni_profile_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _scanned = false;

  Future<Map<String, dynamic>?> _getAlumniById(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(
              'alumni') // ✅ change if your collection is named differently
          .doc(docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id; // keep ID
        return data;
      }
    } catch (e) {
      debugPrint("❌ Firestore error: $e");
    }
    return null;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return; // Prevent multiple triggers
    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _scanned = true);

      final alumniData = await _getAlumniById(code);

      if (alumniData != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AlumniProfileScreen(alumniData: alumniData),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No alumni found for this QR")),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        fit: BoxFit.cover,
        onDetect: _onDetect,
      ),
    );
  }
}
