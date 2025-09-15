import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/profile/profile_edit_screen.dart';
import 'package:cs261_project/profile/profile_model.dart';
import 'package:cs261_project/profile/profile_service.dart';
import 'package:cs261_project/student/user_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRoleDispatcher extends StatefulWidget {
  const UserRoleDispatcher({super.key});

  @override
  State<UserRoleDispatcher> createState() => _UserRoleDispatcherState();
}

class _UserRoleDispatcherState extends State<UserRoleDispatcher> {
  final ProfileService _profileService = ProfileService();
  Stream<Profile?>? _profileStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileStream = _profileService.getProfileStreamByUid(user.uid);
    }
    print('UserRoleDispatcher: initState called'); // Debug log
  }

  @override
  Widget build(BuildContext context) {
    print('UserRoleDispatcher: build called'); // Debug log

    if (_profileStream == null) {
      return const Scaffold(
        body: Center(child: Text("Authenticating...")),
      );
    }

    return StreamBuilder<Profile?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}'); // Debug log

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}'); // Debug log
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('No profile data, signing out'); // Debug log
          // User exists in Auth but no Firestore data → sign out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });
          return const Scaffold(
            body: Center(child: Text("Inconsistent data. Signing out...")),
          );
        }

        final profile = snapshot.data!;
        print(
            'Profile loaded: ${profile.name}, role: ${profile.role}'); // Debug log

        // Gatekeeper 1: Force profile completion
        if (profile.isProfileComplete != true) {
          print('Profile incomplete, redirecting to edit'); // Debug log
          return ProfileEditScreen(userDocumentId: profile.docId!);
        }

        // Gatekeeper 2: Route based on role
        if (profile.role == 'admin') {
          print('Routing to AdminHomeScreen'); // Debug log
          return const AdminHomeScreen();
        } else {
          print('Routing to UserHomeScreen'); // Debug log
          return const UserHomeScreen();
        }
      },
    );
  }
}
