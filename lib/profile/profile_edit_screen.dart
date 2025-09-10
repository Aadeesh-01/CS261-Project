import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_model.dart';
import 'profile_service.dart';

// Renamed from ProfileScreen to ProfileEditScreen for clarity
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController rollCtrl = TextEditingController();
  final TextEditingController interestCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;
  String? _profilePicUrl;
  late final String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // It's safer to schedule the pop for after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return;
    }
    uid = user.uid;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        nameCtrl.text = profile.name ?? '';
        rollCtrl.text = profile.rollNo ?? '';
        interestCtrl.text = profile.interest ?? '';
        bioCtrl.text = profile.bio ?? '';
        yearCtrl.text = profile.year ?? '';
        _profilePicUrl = profile.picture;
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      if (mounted) setState(() => _isUploading = true);

      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      File file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser!;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref('profile_pictures/${user.uid}/avatar.jpg');
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update local UI state
      if (mounted) {
        setState(() {
          _profilePicUrl = downloadUrl;
        });
      }
    } catch (e) {
      print("Failed to pick/upload image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload image. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final profile = Profile(
          name: nameCtrl.text,
          rollNo: rollCtrl.text,
          interest: interestCtrl.text,
          bio: bioCtrl.text,
          year: yearCtrl.text,
          picture: _profilePicUrl,
        );

        await _profileService.saveProfile(uid, profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile Saved!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back and pass 'true' to indicate a successful update.
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't save profile. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _showImageSourceActionSheet,
                      child: CircleAvatar(
                        key: ValueKey(_profilePicUrl),
                        radius: 50,
                        backgroundImage: _profilePicUrl != null && !_isUploading
                            ? NetworkImage(_profilePicUrl!)
                            : null,
                        backgroundColor: Colors.blueAccent.withOpacity(0.8),
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : _profilePicUrl == null
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.white)
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Your Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                      controller: nameCtrl,
                      label: 'Name',
                      icon: Icons.person_outline),
                  _buildTextField(
                      controller: rollCtrl,
                      label: 'Roll No',
                      icon: Icons.school_outlined,
                      isNumeric: true),
                  _buildTextField(
                      controller: yearCtrl,
                      label: 'Year',
                      icon: Icons.calendar_today_outlined,
                      isNumeric: true),
                  _buildTextField(
                      controller: interestCtrl,
                      label: 'Interests',
                      icon: Icons.favorite_border),
                  _buildTextField(
                      controller: bioCtrl,
                      label: 'Bio',
                      icon: Icons.edit_outlined),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Save Changes",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
