// lib/screen/user_home_screen.dart
import 'package:cs261_project/screen/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Your existing HomeScreen code can go here
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("This is the regular user interface."),
      ),
    );
  }
}
