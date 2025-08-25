import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs261_project/profile/profile_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user details (basic auth)
  AppUser? getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      return AppUser(
        uid: user.uid,
        name: user.displayName ?? "No Name",
        email: user.email ?? "No Email",
        photoUrl: user.photoURL,
      );
    }
    return null;
  }

  // Save Profile data to Firestore
  Future<void> saveUserProfile(Profile profile) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection("users").doc(user.uid).set(profile.toMap());
    }
  }

  // Get Profile data from Firestore
  Future<Profile?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection("users").doc(user.uid).get();
      if (doc.exists) {
        return Profile.fromMap(doc.data()!);
      }
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
