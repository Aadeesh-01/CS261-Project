// lib/screen/user_home_screen.dart
import 'package:cs261_project/profile/profile_screen.dart';
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
        title: const Text('Welcome Student'),
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
      drawer: Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center, // Centered content
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white, // Contrasting color
                    radius: 36,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(36),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      )),
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.blueAccent), // Added an icon
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "User Name", // Placeholder for user's name
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            const Spacer(), // Pushes the logout to the bottom
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // Relying on the StreamBuilder is cleaner
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text("This is the regular user interface."),
      ),
    );
  }
}
