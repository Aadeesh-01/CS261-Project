import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AlumniProfileScreen extends StatelessWidget {
  final Map<String, dynamic> alumniData;

  const AlumniProfileScreen({Key? key, required this.alumniData})
      : super(key: key);

  // A reusable widget for displaying details with an icon
  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Safely extract data ---
    final name = alumniData['name'] ?? 'Alumni Profile';
    final company = alumniData['company'] ?? 'Not specified';
    final skills = alumniData['skills'] ?? 'No skills listed';
    final batch = alumniData['batch']?.toString() ?? 'N/A';

    // A unique identifier for the QR code (email, user ID, etc.)
    final qrData =
        alumniData['email'] ?? alumniData['objectID'] ?? 'no-unique-id';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // --- Profile Header ---
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- Details Section ---
                  _buildDetailRow(context,
                      icon: Icons.school_outlined,
                      title: 'Batch',
                      value: batch),
                  _buildDetailRow(context,
                      icon: Icons.construction_outlined,
                      title: 'Skills',
                      value: skills),
                  const SizedBox(height: 20),

                  // --- QR Code Section ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180.0,
                          gapless: false, // Prevents rendering artifacts
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan to connect or view profile',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
