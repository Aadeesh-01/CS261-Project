import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MakeAdminButton extends StatefulWidget {
  const MakeAdminButton({super.key});

  @override
  State<MakeAdminButton> createState() => _MakeAdminButtonState();
}

class _MakeAdminButtonState extends State<MakeAdminButton> {
  bool _loading = false;
  String _status = '';

  Future<void> makeUserAdmin(String email) async {
    try {
      setState(() {
        _loading = true;
        _status = '';
      });

      // Make sure the region matches your deployed function
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: "asia-south1")
              .httpsCallable('addAdminRole');

      final result = await callable.call({'email': 'admin@example.com'});

      setState(() {
        _status = result.data['message'] ?? '✅ User made admin successfully!';
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _status = '❌ ${e.message}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _loading
              ? null
              : () => makeUserAdmin('admin@example.com'), // change this email
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Make User Admin'),
        ),
        const SizedBox(height: 12),
        Text(
          _status,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}
