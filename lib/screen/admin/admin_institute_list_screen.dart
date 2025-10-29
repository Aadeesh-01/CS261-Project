import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminInstituteListScreen extends StatefulWidget {
  const AdminInstituteListScreen({super.key});

  @override
  State<AdminInstituteListScreen> createState() =>
      _AdminInstituteListScreenState();
}

class _AdminInstituteListScreenState extends State<AdminInstituteListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _instituteNameController = TextEditingController();
  bool _isAdding = false;

  Future<void> _addInstitute() async {
    final name = _instituteNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Institute name cannot be empty"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      await _firestore.collection('institutes').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _instituteNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Institute added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteInstitute(String id) async {
    try {
      await _firestore.collection('institutes').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Institute deleted"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _instituteNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Institutes"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _instituteNameController,
                    decoration: const InputDecoration(
                      labelText: "Institute Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _isAdding
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addInstitute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                        child: const Text("Add"),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Institute List",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('institutes')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No institutes added yet."),
                    );
                  }

                  final institutes = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: institutes.length,
                    itemBuilder: (context, index) {
                      final doc = institutes[index];
                      final name = doc['name'] ?? 'Unnamed';
                      final id = doc.id;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.account_balance,
                              color: Colors.blueAccent),
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInstitute(id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
