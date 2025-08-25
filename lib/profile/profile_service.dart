import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveProfile(String uid, Profile profile) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<Profile?> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return Profile.fromMap(doc.data()!);
    }
    return null;
  }
}
