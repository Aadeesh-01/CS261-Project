import 'package:flutter/material.dart';
import 'package:cs261_project/profile/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  final Profile? profile; // null means create new

  const ProfileScreen({super.key, this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _interestController;
  late TextEditingController _bioController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    // If profile exists, pre-fill. Else empty.
    _nameController = TextEditingController(text: widget.profile?.name ?? "");
    _rollNoController =
        TextEditingController(text: widget.profile?.rollNo ?? "");
    _interestController =
        TextEditingController(text: widget.profile?.interest ?? "");
    _bioController = TextEditingController(text: widget.profile?.bio ?? "");
    _yearController = TextEditingController(text: widget.profile?.year ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _interestController.dispose();
    _bioController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final newProfile = Profile(
        name: _nameController.text,
        rollNo: _rollNoController.text,
        interest: _interestController.text,
        bio: _bioController.text,
        year: _yearController.text,
        pictureUrl: widget.profile?.pictureUrl ?? "",
      );

      // TODO: Save newProfile.toMap() to Firestore
      debugPrint("Profile saved: ${newProfile.toMap()}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = widget.profile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasProfile ? "Edit Profile" : "Create Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.profile?.pictureUrl.isNotEmpty == true
                      ? NetworkImage(widget.profile!.pictureUrl)
                      : null,
                  child: widget.profile?.pictureUrl.isEmpty ?? true
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your name" : null,
                ),
                TextFormField(
                  controller: _rollNoController,
                  decoration: const InputDecoration(labelText: "Roll No"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your roll number" : null,
                ),
                TextFormField(
                  controller: _interestController,
                  decoration: const InputDecoration(labelText: "Interest"),
                ),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: "Year"),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: Text(hasProfile ? "Update Profile" : "Create Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
