import 'package:cloud_firestore/cloud_firestore.dart';

class Alumni {
  final String docId; // The unique ID from Firestore
  final String alumniId;
  final String name;
  final String email;
  final String role;
  final String uid;
  final String year;
  final bool isProfileComplete;
  final Timestamp createdAt;

  Alumni({
    required this.docId,
    required this.alumniId,
    required this.name,
    required this.email,
    required this.role,
    required this.uid,
    required this.year,
    required this.isProfileComplete,
    required this.createdAt,
  });

  // Factory constructor to create an Alumni instance from a Firestore document
  factory Alumni.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Alumni(
      docId: doc.id, // Get the document ID
      alumniId: data['alumniId'] ?? '',
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? '',
      role: data['role'] ?? 'alumni',
      uid: data['uid'] ?? '',
      year: data['year'] ?? '',
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
