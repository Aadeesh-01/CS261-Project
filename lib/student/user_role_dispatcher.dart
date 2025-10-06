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

    // 🧩 Check if user is admin
    final adminDoc =
        await FirebaseFirestore.instance.collection('users').doc('s1').get();

    if (adminDoc.exists && adminDoc['email'] == user.email) {
      print('Admin login detected');
      // Construct a mock profile for admin
      final adminProfile = Profile(
        docId: 's1',
        name: adminDoc['name'] ?? 'Admin',
        role: 'admin',
        isProfileComplete: adminDoc['isProfileComplete'] ?? true,
      );

      // Convert it into a one-shot stream
      setState(() {
        _profileStream = Stream.value(adminProfile);
      });
      return;
    }

    // 🧩 If not admin → get profile stream from Firestore
    setState(() {
      _profileStream = _profileService.getProfileStreamByUid(user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profileStream == null) {
      return const Scaffold(
        body: Center(child: Text("Authenticating...")),
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
          print('Stream error: ${snapshot.error}');
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('No profile found, signing out...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });
          return const Scaffold(
            body: Center(child: Text("Inconsistent data. Signing out...")),
          );
        }

        final profile = snapshot.data!;
        print('Profile loaded: ${profile.name}, role: ${profile.role}');

        // 🚧 Force profile completion before proceeding
        if (profile.isProfileComplete != true) {
          print('Profile incomplete → redirecting to edit');
          return ProfileEditScreen(userDocumentId: profile.docId!);
        }

        // 🧭 Navigate based on role
        if (profile.role == 'admin') {
          print('Routing → AdminHomeScreen');
          return const AdminHomeScreen();
        } else if (profile.role == 'student' || profile.role == 'alumni') {
          print('Routing → UserHomeScreen');
          return const UserHomeScreen();
        } else {
          print('Unknown role → Signing out for safety');
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
