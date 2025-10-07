import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAddAlumniScreen extends StatefulWidget {
  const AdminAddAlumniScreen({super.key});

  @override
  State<AdminAddAlumniScreen> createState() => _AdminAddAlumniScreenState();
}

class _AdminAddAlumniScreenState extends State<AdminAddAlumniScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
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
    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: "asia-south1")
          .httpsCallable("createAlumniAccount");

      final result = await callable.call(<String, dynamic>{
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "name": _nameController.text.trim(),
        "year": _yearController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.data["message"]),
            backgroundColor: Colors.green),
      );

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _yearController.clear();
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error: ${e.message}"), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Unexpected error: $e"), backgroundColor: Colors.red),
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
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 12),
            TextField(
                controller: _yearController,
                decoration:
                    const InputDecoration(labelText: "Graduation Year")),
            const SizedBox(height: 12),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createAlumni, child: const Text("Add Alumni")),
          ],
        ),
      ),
    );
  }
}
