import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_model.dart';

class ProfileService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Gets a real-time stream of a user's profile by their UID (document ID).
  Stream<Profile?> getProfileStreamByUid(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return Profile.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Fetches a user's profile once by their UID.
  Future<Profile?> getProfile(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists) {
        return Profile.fromJson(
            docSnapshot.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print("Error getting profile: $e");
      return null;
    }
  }

  /// Updates profile data to the user's document using their UID.
  /// Will not overwrite uid, role, userId unless explicitly included.
  Future<void> saveProfile(String uid, Profile profile) async {
    final data = <String, dynamic>{
      if (profile.name != null) 'name': profile.name,
      if (profile.bio != null) 'bio': profile.bio,
      if (profile.interest != null) 'interest': profile.interest,
      if (profile.year != null) 'year': profile.year,
      if (profile.rollNo != null) 'rollNo': profile.rollNo,
      if (profile.picture != null) 'picture': profile.picture,
      if (profile.isProfileComplete != null)
        'isProfileComplete': profile.isProfileComplete,
      //if (profile.createdAt != null) 'createdAt': profile.createdAt,
    };

    try {
      await _usersCollection.doc(uid).update(data);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        // If document doesn't exist, fallback to set
        await _usersCollection.doc(uid).set(data);
      } else {
        print("FirebaseException saving profile: $e");
        rethrow;
      }
    } catch (e) {
      print("Error saving profile: $e");
      rethrow;
    }
  }
}
