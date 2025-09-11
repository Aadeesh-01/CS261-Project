import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 👈 The missing import is here

class MakeAdminButton extends StatelessWidget {
  // --- CONFIGURATION ---
  // 👇 IMPORTANT: Change this to the email you want to make an admin.
  final String emailToMakeAdmin;
  // ---------------------

  const MakeAdminButton({
    super.key,
    required this.emailToMakeAdmin,
  });

  Future<void> _setAdminRole(BuildContext context) async {
    // Show a confirmation dialog before making such a critical change.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content:
            Text('Are you sure you want to make "$emailToMakeAdmin" an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action canceled.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing...')),
    );

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'us-central1')
              .httpsCallable('addAdminRole');

      final result = await callable.call({'email': emailToMakeAdmin});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Success: ${result.data['message']}'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ERROR: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _setAdminRole(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
      child: const Text('Make User Admin (Temporary)'),
    );
  }
}
