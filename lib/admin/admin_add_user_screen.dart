import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAddUserScreen extends StatefulWidget {
  const AdminAddUserScreen({super.key});

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: "us-central1")
              .httpsCallable("createUserAccount");

      await callable.call<Map<String, dynamic>>({
        "email": email,
        "password": password,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ User created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _emailController.clear();
      _passwordController.clear();
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
      appBar: AppBar(title: const Text("Admin - Add User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                  labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text("Add User"),
                  ),
          ],
        ),
      ),
    );
  }
}
