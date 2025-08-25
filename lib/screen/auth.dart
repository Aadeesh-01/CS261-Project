import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/student/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedInstitute;
  String? selectedRole;

  List<String> institutes = [];
  List<String> roles = ["Admin", "Faculty", "Alumni", "Student"];

  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // NEW: State variable to track loading for the entire screen
  bool isScreenLoading = true;
  // NEW: State variable to track loading for the login button specifically
  bool isLoginLoading = false;

  @override
  void initState() {
    super.initState();
    fetchInstitutes();
  }

  Future<void> fetchInstitutes() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection("institutes").get();
      setState(() {
        institutes = snapshot.docs.map((doc) => doc["name"] as String).toList();
        isScreenLoading = false; // Stop loading when data is fetched
      });
    } catch (e) {
      setState(() => isScreenLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching institutes: $e")),
      );
    }
  }

  Future<void> loginUser() async {
    // --- DEBUG STEP 2: Show loading indicator ---
    setState(() {
      isLoginLoading = true;
    });

    try {
      print("Attempting to sign in with email: ${emailController.text.trim()}");

      // Step 1: Sign in the user with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user!;
      print("Sign in successful. User UID: ${user.uid}");

      // Step 2: Fetch the user's document from Firestore
      print("Fetching user document from Firestore...");
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      // Step 3: Check the role and navigate
      if (docSnapshot.exists) {
        final String role = docSnapshot.data()!['role'];
        print("User document found. Role: $role");

        // Navigate to the correct screen
        if (mounted) {
          // Check if the widget is still in the tree
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => role == 'Admin'
                  ? const AdminHomeScreen()
                  : const UserHomeScreen(),
            ),
          );
        }
      } else {
        print(
            "Error: User document not found in Firestore for UID: ${user.uid}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data not found in database.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An unknown error occurred")),
      );
    } catch (e) {
      print("An unexpected error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      // --- DEBUG STEP 3: Hide loading indicator ---
      if (mounted) {
        setState(() {
          isLoginLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    // (Your resetPassword function is fine, no changes needed here)
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email first")),
      );
      return;
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isScreenLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Alumni Connect Login",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // (Dropdowns and TextFields remain the same)
                    /* DropdownButtonFormField<String>(
                      value: selectedInstitute,
                      hint: const Text("Select Institute"),
                      items: institutes
                          .map((inst) => DropdownMenuItem(
                                value: inst,
                                child: Text(inst),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedInstitute = value),
                    ),
                    const SizedBox(height: 15),*/
                    /* DropdownButtonFormField<String>(
                      value: selectedRole,
                      hint: const Text("Select Role"),
                      items: roles
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedRole = value),
                    ),
                    const SizedBox(height: 15),*/
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                    ),
                    const SizedBox(height: 20),
                    // --- NEW: Conditional UI for login button ---
                    isLoginLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: loginUser,
                            child: const Text("Login"),
                          ),
                    TextButton(
                      onPressed: resetPassword,
                      child: const Text("Forgot Password?"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}


/*
import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  void adminScreen() {
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AdminHomeScreen(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: adminScreen, child: Text('admin screen'))
        ],
      ),
    );
  }
}
*/