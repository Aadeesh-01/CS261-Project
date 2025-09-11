import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_model.dart';

class ProfileService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Fetches a user's profile using their custom document ID (e.g., 's1').
  Future<Profile?> getProfile(String docId) async {
    try {
      final docSnapshot = await _usersCollection.doc(docId).get();
      if (docSnapshot.exists) {
        return Profile.fromJson(
            docSnapshot.data() as Map<String, dynamic>, docId);
      }
      return null;
    } catch (e) {
      print("Error getting profile: $e");
      return null;
    }
  }

  /// Finds the custom document ID (e.g., 's1') by querying for the Auth UID.
  Future<String?> getProfileDocumentIdByUid(String uid) async {
    try {
      final querySnapshot =
          await _usersCollection.where('uid', isEqualTo: uid).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print("Error finding document by UID: $e");
      return null;
    }
  }

  /// Gets a real-time stream of a user's profile by their Auth UID.
  Stream<Profile?> getProfileStreamByUid(String uid) {
    return _usersCollection
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Profile.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Saves profile data to the user's document using their custom ID.
  Future<void> saveProfile(String docId, Profile profile) async {
    try {
      await _usersCollection.doc(docId).set(
            profile.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      print("Error saving profile: $e");
      rethrow;
    }
  }
}
