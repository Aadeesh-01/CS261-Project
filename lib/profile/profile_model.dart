// lib/models/profile_model.dart
class Profile {
  String name;
  String rollNo;
  String interest;
  String bio;
  String year;
  String pictureUrl;

  Profile({
    required this.name,
    required this.rollNo,
    required this.interest,
    required this.bio,
    required this.year,
    required this.pictureUrl,
  });

  // Factory method to create Profile from Firestore/Map
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] ?? '',
      rollNo: map['rollNo'] ?? '',
      interest: map['interest'] ?? '',
      bio: map['bio'] ?? '',
      year: map['year'] ?? '',
      pictureUrl: map['pictureUrl'] ?? '',
    );
  }

  // Convert Profile to Map (for Firestore/JSON)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'interest': interest,
      'bio': bio,
      'year': year,
      'pictureUrl': pictureUrl,
    };
  }
}
