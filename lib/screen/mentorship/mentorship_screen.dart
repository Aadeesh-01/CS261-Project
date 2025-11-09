import 'package:flutter/material.dart';

class MentorshipScreen extends StatelessWidget {
  final String instituteId;
  const MentorshipScreen({super.key, required this.instituteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mentorship'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 48, color: Colors.green.shade600),
            const SizedBox(height: 16),
            const Text(
              'Mentorship coming soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text('Institute: $instituteId',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
