import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 👈 The missing import is here

class MakeAdminButton extends StatelessWidget {
  // --- CONFIGURATION ---
  // 👇 IMPORTANT: Change this to the email you want to make an admin.
  // ---------------------

  const MakeAdminButton({
    super.key,
  });

  Future<void> makeUserAdmin(String email) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('addAdminRole');

    final result = await callable.call({'email': email});
    print(result.data['message']);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => makeUserAdmin('admin@example.com'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
      child: const Text('Make User Admin (Temporary)'),
    );
  }
}
