import 'package:cs261_project/profile/profile_edit_screen.dart';
import 'package:cs261_project/profile/profile_model.dart';
import 'package:cs261_project/profile/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Profile? _profile;
  String? _userDocumentId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      return;
    }

    final docId = await _profileService.getProfileDocumentIdByUid(user.uid);

    if (docId != null) {
      if (mounted) {
        setState(() {
          _userDocumentId = docId;
        });
      }
      await _loadProfile(docId);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProfile(String docId) async {
    final profile = await _profileService.getProfile(docId);
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
              if (_userDocumentId == null) return;

              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileEditScreen(userDocumentId: _userDocumentId!),
                ),
              );

              if (updated == true && _userDocumentId != null) {
                if (mounted) {
                  setState(() => _isLoading = true);
                  _loadProfile(_userDocumentId!);
                }
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text("No profile data found."))
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
        subtitle:
            Text(value != null && value.isNotEmpty ? value : "Not provided"),
      ),
    );
  }
}
