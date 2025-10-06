import 'package:cs261_project/admin/button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAddAlumniScreen extends StatefulWidget {
  const AdminAddAlumniScreen({super.key});

  @override
  State<AdminAddAlumniScreen> createState() => _AdminAddAlumniScreenState();
}

class _AdminAddAlumniScreenState extends State<AdminAddAlumniScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _createAlumni() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String name = _nameController.text.trim();
    final String year = _yearController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Call your Cloud Function to create alumni
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: "us-central1")
              .httpsCallable("createAlumniAccount");

      await callable.call<Map<String, dynamic>>({
        "email": email,
        "password": password,
        "name": name,
        "year": year,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Alumni created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _yearController.clear();
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ERROR (${e.code}): ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
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
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: "Graduation Year",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createAlumni,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      child: const Text("Add Alumni"),
                    ),
              MakeAdminButton(),
            ],
          ),
        ),
      ),
    );
  }
}
