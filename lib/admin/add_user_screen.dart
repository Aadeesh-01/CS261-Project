import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// This screen provides a form for an admin to create a new user.
/// It securely calls a Cloud Function ('createNewUser') to perform the user creation
/// on the backend, ensuring that only authenticated admins can perform this action.
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  // A key to identify and validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage the text in the email and password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables to manage the UI during the function call
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  /// Calls the 'createNewUser' Cloud Function.
  Future<void> _createNewUser() async {
    // First, validate the form fields to ensure they are not empty and meet criteria.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set the state to show a loading indicator and clear previous messages.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Get a reference to the callable Cloud Function by its exact name.
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createNewUser');

      // 2. Call the function, passing the new user's email and password as parameters.
      final result = await callable.call<Map<String, dynamic>>({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      // 3. If the call is successful, display the success message returned from the function.
      setState(() {
        _successMessage = result.data['message'];
        // Clear the form fields for the next entry.
        _emailController.clear();
        _passwordController.clear();
      });
    } on FirebaseFunctionsException catch (e) {
      // Handle specific errors returned by the Cloud Function (e.g., permission denied).
      setState(() {
        _errorMessage = e.message ?? "An unknown function error occurred.";
      });
    } catch (e) {
      // Handle any other unexpected errors (e.g., network issues).
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    } finally {
      // 4. No matter the outcome, stop the loading indicator.
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed from the widget tree.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create a New User Account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Email input field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'New User Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password input field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Temporary Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // Show a loading circle or the button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _createNewUser,
                              child: const Text('Create User',
                                  style: TextStyle(fontSize: 16)),
                            ),
                      const SizedBox(height: 20),
                      // Display success or error messages
                      if (_successMessage != null)
                        Text(
                          _successMessage!,
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
