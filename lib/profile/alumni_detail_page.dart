import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AlumniDetailPage extends StatefulWidget {
  final Map<String, dynamic> alumniData;

  const AlumniDetailPage({Key? key, required this.alumniData})
      : super(key: key);

  @override
  State<AlumniDetailPage> createState() => _AlumniDetailPageState();
}

class _AlumniDetailPageState extends State<AlumniDetailPage> {
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.alumniData;

    final name = data['name'] ?? 'Unknown';
    final company = data['company'] ?? 'Unknown';

    // Handle skills as a list or fallback string
    final skills = (data['skills'] is List)
        ? (data['skills'] as List).join(', ')
        : (data['skills']?.toString() ?? 'No skills listed');

    // Convert int to string safely
    final batch =
        (data['batch'] != null) ? data['batch'].toString() : 'Unknown';
    final email = data['email'] ?? 'no-email@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show QR Code',
            onPressed: () {
              setState(() {
                _showQR = !_showQR;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(icon: Icons.person, label: "Name", value: name),
            _buildInfoTile(
                icon: Icons.business, label: "Company", value: company),
            _buildInfoTile(icon: Icons.school, label: "Batch", value: batch),
            _buildInfoTile(icon: Icons.email, label: "Email", value: email),
            _buildInfoTile(icon: Icons.code, label: "Skills", value: skills),
            const SizedBox(height: 20),
            if (_showQR) ...[
              Center(
                child: Column(
                  children: [
                    Text("QR Code",
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: email, // You can use UID or another unique field
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    )),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
