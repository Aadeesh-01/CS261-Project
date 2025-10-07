import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/profile/profile_edit_screen.dart';
import 'package:cs261_project/profile/profile_model.dart';
import 'package:cs261_project/profile/profile_service.dart';
import 'package:cs261_project/student/user_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _initProfileStream();
  }

  Future<void> _initProfileStream() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user logged in');
      return;
    }

    print('UserRoleDispatcher: Logged in as ${user.email}');

    final firestore = FirebaseFirestore.instance;

    // Check "users" collection for students/admins
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _profileStream = _profileService.getProfileStreamByUid(user.uid);
      });
      return;
    }

    // Check "alumni" collection for alumni
    final alumniDoc = await firestore.collection('alumni').doc(user.uid).get();
    if (alumniDoc.exists) {
      final alumniProfile = Profile(
        docId: alumniDoc.id,
        name: alumniDoc['name'] ?? "Alumni Member",
        role: "alumni",
        isProfileComplete: alumniDoc['isProfileComplete'] ?? false,
      );
      setState(() {
        _profileStream = Stream.value(alumniProfile);
      });
      return;
    }

    // If no profile found → sign out
    print('No profile found → signing out');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAuth.instance.signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profileStream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Profile?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });
          return const Scaffold(
            body: Center(child: Text("No profile found. Signing out...")),
          );
        }

        final profile = snapshot.data!;
        print('Profile loaded: ${profile.name}, role: ${profile.role}');

        // Force profile completion before proceeding
        if (profile.isProfileComplete != true) {
          return ProfileEditScreen(userDocumentId: profile.docId!);
        }

        // Routing based on role
        if (profile.role == 'admin') {
          return const AdminHomeScreen();
        } else if (profile.role == 'student' || profile.role == 'alumni') {
          return const UserHomeScreen();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });
          return const Scaffold(
            body: Center(child: Text("Unknown role. Signing out...")),
          );
        }
      },
    );
  }
}
