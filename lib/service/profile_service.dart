import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs261_project/model/alumni_model.dart';
import 'package:cs261_project/model/profile_model.dart';

class ProfileService {
  final String instituteId;
  late final CollectionReference _profilesCollection;
  late final CollectionReference _participantsCollection;

  // ✅ FIX: Require an instituteId to initialize the service.
  ProfileService({required this.instituteId}) {
    // ✅ FIX: Point to the correct nested subcollections.
    _profilesCollection = FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('profiles');

    _participantsCollection = FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('participants');
  }

  /// ✅ FIX: Simplified stream directly from the correct 'profiles' subcollection.
  /// Gets a profile stream for a given user ID.
  Stream<Profile?> getProfileStream(String uid) {
    return _profilesCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return Profile.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      // Yield null if the user has no profile document.
      return null;
    });
  }

  /// Fetches a user's profile once by their UID.
  Future<Profile?> getProfile(String uid) async {
    try {
      final docSnapshot = await _profilesCollection.doc(uid).get();
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

  /// Returns the participant role (e.g., 'student', 'alumni', 'admin') for a UID within this institute.
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _participantsCollection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  /// ✅ FIX: Efficiently saves/updates profile data using set with merge.
  /// This performs an "upsert" (update if exists, create if not).
  Future<void> saveProfile(String uid, Profile profile) async {
    try {
      await _profilesCollection
          .doc(uid)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (e) {
      print("Error saving profile: $e");
      rethrow;
    }
  }

  /// ✅ FIX: Queries the 'participants' collection with a filter for the 'alumni' role.
  /// Gets a real-time stream of all alumni documents.
  Stream<List<Alumni>> getAlumniStream() {
    return _participantsCollection
        .where('role', isEqualTo: 'alumni')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Alumni.fromFirestore(doc);
      }).toList();
    });
  }

  /// Fetches the list of all alumni just once.
  Future<List<Alumni>> getAlumniOnce() async {
    try {
      final snapshot = await _participantsCollection
          .where('role', isEqualTo: 'alumni')
          .get();
      return snapshot.docs.map((doc) => Alumni.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching alumni: $e");
      return [];
    }
  }
}
