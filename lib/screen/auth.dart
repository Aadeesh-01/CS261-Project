import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs261_project/service/user_role_dispatcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _email = '';
  String _password = '';
  String? _selectedInstituteId;
  List<Map<String, dynamic>> _institutes = [];

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  /// Load all available institutes from Firestore
  Future<void> _loadInstitutes() async {
    try {
      final snapshot = await _firestore.collection('institutes').get();
      setState(() {
        _institutes = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name']})
            .toList();
      });
      print("✅ Institutes loaded: ${_institutes.length}");
    } catch (e) {
      print("❌ Failed to load institutes: $e");
      _showError("Failed to load institutes.");
    }
  }

  /// Handle login process
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedInstituteId == null) {
      _showError('Please select an institute.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("--- LOGIN START ---");
      print("Email: $_email");
      print("Institute ID: $_selectedInstituteId");

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );
      final user = userCredential.user;
      if (user == null) throw Exception("User is null after login");

      print("✅ Auth success: ${user.uid}");

      // Fetch participant doc from selected institute
      final participantRef = _firestore
          .collection('institutes')
          .doc(_selectedInstituteId!)
          .collection('participants')
          .doc(user.uid);

      final participantDoc = await participantRef.get();

      if (!participantDoc.exists) {
        print("🚨 No participant document found for this user.");
        await FirebaseAuth.instance.signOut();
        throw Exception('User not registered under this institute.');
      }

      print("✅ Firestore doc found: ${participantDoc.data()}");

      // Save selected institute for auto-login next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastInstituteId', _selectedInstituteId!);
      print("🏫 Saved lastInstituteId: $_selectedInstituteId");

      if (!mounted) return;

      // Navigate to role dispatcher
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UserRoleDispatcher(instituteId: _selectedInstituteId!),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuth error: ${e.code} - ${e.message}");
      _showError(e.message ?? "Login failed. Check credentials.");
    } catch (e) {
      print("❌ General login error: $e");
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedInstituteId,
                      items: _institutes
                          .map(
                            (inst) => DropdownMenuItem<String>(
                              value: inst['id'],
                              child: Text(inst['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedInstituteId = v),
                      decoration: const InputDecoration(
                        labelText: 'Select Institute',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null ? 'Please select an institute' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter your email' : null,
                      onSaved: (v) => _email = v!,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) => v!.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                      onSaved: (v) => _password = v!,
                    ),
                    const SizedBox(height: 25),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _loginUser,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
