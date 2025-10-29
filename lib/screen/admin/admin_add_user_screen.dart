import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAddParticipantScreen extends StatefulWidget {
  const AdminAddParticipantScreen({super.key});

  @override
  State<AdminAddParticipantScreen> createState() =>
      _AdminAddParticipantScreenState();
}

class _AdminAddParticipantScreenState extends State<AdminAddParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _email = '';
  String _password = '';
  String? _selectedInstituteId;
  String? _selectedRole;
  List<Map<String, dynamic>> _institutes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    final snapshot = await _firestore.collection('institutes').get();
    setState(() {
      _institutes = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
    });
  }

  Future<void> _addParticipant() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in as an admin.");
      }

      final adminDoc = await _firestore
          .collection('participants')
          .doc(currentUser.uid)
          .get();

      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        throw Exception("Only admins can add new participants.");
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      await _firestore
          .collection('participants')
          .doc(userCredential.user!.uid)
          .set({
        'email': _email,
        'role': _selectedRole ?? 'student',
        'instituteId': _selectedInstituteId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Participant added successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Participant")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedInstituteId,
                items: _institutes
                    .map(
                      (inst) => DropdownMenuItem<String>(
                        value: inst['id'] as String,
                        child: Text(inst['name']),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedInstituteId = value),
                decoration: const InputDecoration(
                  labelText: 'Select Institute',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null ? 'Please select an institute' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'alumni', child: Text('Alumni')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v),
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _email = v!,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (v) => _password = v!,
                validator: (v) => v!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addParticipant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Add Participant'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
