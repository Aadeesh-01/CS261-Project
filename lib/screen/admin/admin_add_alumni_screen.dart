import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAddAlumniScreen extends StatefulWidget {
  final String instituteId;
  const AdminAddAlumniScreen({super.key, required this.instituteId});

  @override
  State<AdminAddAlumniScreen> createState() => _AdminAddAlumniScreenState();
}

class _AdminAddAlumniScreenState extends State<AdminAddAlumniScreen> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAlumni() async {
    if (_nameController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('createParticipantAccount');
      final result = await callable.call({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _nameController.text.trim(),
        'role': 'alumni',
        'year': _yearController.text.trim(),
        'instituteId': widget.instituteId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data['message'] ?? "Alumni added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _yearController.clear();
      _emailController.clear();
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Add Alumni")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: "Graduation Year"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createAlumni,
                      child: const Text("Add Alumni"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
