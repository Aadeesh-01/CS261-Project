//import 'package:cs261_project/student/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';
import 'profile_model.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Profile? _profile;
  late final String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    uid = user.uid;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile(uid);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileEditScreen(),
                ),
              );
              if (updated == true) _loadProfile();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text("No profile found"))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _profile!.picture != null
                            ? () => _showImageDialog(_profile!.picture!)
                            : null,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _profile!.picture != null
                              ? NetworkImage(_profile!.picture!)
                              : null,
                          backgroundColor: Colors.blueGrey,
                          child: _profile!.picture == null
                              ? const Icon(Icons.person,
                                  size: 70, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _profile!.name ?? "Unnamed",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _infoTile("Roll No", _profile!.rollNo),
                    _infoTile("Year", _profile!.year),
                    _infoTile("Interests", _profile!.interest),
                    _infoTile("Bio", _profile!.bio),
                  ],
                ),
    );
  }

  Widget _infoTile(String title, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? "Not provided"),
      ),
    );
  }
}
