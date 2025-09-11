import 'package:cs261_project/profile/profile_edit_screen.dart';
import 'package:cs261_project/profile/profile_model.dart';
import 'package:cs261_project/profile/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- Placeholder Screens ---
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), actions: [
        IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout))
      ]),
      body: const Center(child: Text("Welcome, Admin!")),
    );
  }
}

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Home"), actions: [
        IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout))
      ]),
      body: const Center(child: Text("Welcome, Student!")),
    );
  }
}
// -------------------------

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
    _setupProfileStream();
  }

  void _setupProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileStream = _profileService.getProfileStreamByUid(user.uid);
    }
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
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        // ** THE FIX IS HERE **
        // If a user is authenticated but has no profile document,
        // it's an invalid state. Sign them out.
        if (!snapshot.hasData || snapshot.data == null) {
          // We use a post-frame callback to safely call signOut after the build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });

          // Show a loading indicator while the sign-out is processing.
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Inconsistent data found. Signing out..."),
                  SizedBox(height: 10),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        final docId = profile.docId!;

        // --- THE GATEKEEPER LOGIC ---
        if (profile.isProfileComplete != true) {
          return ProfileEditScreen(userDocumentId: docId);
        }

        if (profile.role == 'admin') {
          return const AdminHomeScreen();
        } else {
          return const StudentHomeScreen();
        }
      },
    );
  }
}
