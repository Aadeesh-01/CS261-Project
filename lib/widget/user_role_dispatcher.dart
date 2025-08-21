import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/screen/splash_screen.dart';
import 'package:cs261_project/screen/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoleDispatcher extends StatelessWidget {
  const UserRoleDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // This should not happen if called from the StreamBuilder, but it's a safe fallback.
      return const SplashScreen();
    }

    // This FutureBuilder is what gets the DocumentSnapshot from Firestore
    return FutureBuilder<DocumentSnapshot>(
      // We use the user.uid from the AUTH object to query the DATABASE
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // While the database query is running, we wait
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // HERE is the correct place to check for existence.
        // `snapshot.data` is the DocumentSnapshot from Firestore.
        // We check if the query had an error, didn't return data, OR the document doesn't exist.
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // Default to the regular user screen if the document is not found
          // or if there's an error.
          return const UserHomeScreen();
        }

        // If we get here, the document EXISTS and we have the data.
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String role = userData['role'] ??
            'Student'; // Default to 'Student' if role field is missing

        if (role == 'Admin') {
          return const AdminHomeScreen();
        } else {
          return const UserHomeScreen();
        }
      },
    );
  }
}
