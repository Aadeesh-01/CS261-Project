import 'package:flutter/material.dart';
import 'profile_model.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final String uid; // Current user UID

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController rollCtrl = TextEditingController();
  final TextEditingController interestCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();
  final TextEditingController pictureCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile(widget.uid);
    if (profile != null) {
      setState(() {
        nameCtrl.text = profile.name ?? '';
        rollCtrl.text = profile.rollNo ?? '';
        interestCtrl.text = profile.interest ?? '';
        bioCtrl.text = profile.bio ?? '';
        yearCtrl.text = profile.year ?? '';
        pictureCtrl.text = profile.picture ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = Profile(
        name: nameCtrl.text,
        rollNo: rollCtrl.text,
        interest: interestCtrl.text,
        bio: bioCtrl.text,
        year: yearCtrl.text,
        picture: pictureCtrl.text,
      );
      await _profileService.saveProfile(widget.uid, profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: rollCtrl,
                decoration: const InputDecoration(labelText: 'Roll No'),
              ),
              TextFormField(
                controller: interestCtrl,
                decoration: const InputDecoration(labelText: 'Interest'),
              ),
              TextFormField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              TextFormField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextFormField(
                controller: pictureCtrl,
                decoration: const InputDecoration(labelText: 'Picture URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
