import 'package:cs261_project/screen/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

import 'package:cs261_project/profile/profile_screen.dart';
import 'package:cs261_project/screen/main_home_screen.dart'; // The home screen we just created

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found.")),
      );
    }

    final pages = [
      const MainHomeScreen(),
      const ProfileScreen(), // 👈 only ProfileScreen here
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Student"),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person,
                        size: 40, color: Colors.blueAccent)
                    : null,
              ),
              accountName: Text(
                user.displayName ?? "User Name",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              accountEmail: Text(
                user.email ?? "user@email.com",
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ));
              },
            ),
          ],
        ),
      ),
      body: LiquidSwipe(
        pages: pages,
        enableLoop: false,
        waveType: WaveType.liquidReveal,
        slideIconWidget:
            const Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
      ),
    );
  }
}
