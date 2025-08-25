import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/screen/splash_screen.dart';
import 'package:cs261_project/student/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoleDispatcher extends StatelessWidget {
  const UserRoleDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SplashScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const UserHomeScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String role = userData['role'] ?? 'Student';

        if (role == 'Admin') {
          return const AdminHomeScreen();
        } else {
          return const UserHomeScreen();
        }
      },
    );
  }
}
