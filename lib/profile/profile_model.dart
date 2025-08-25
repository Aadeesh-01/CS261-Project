// profile_model.dart

// Represents the Firebase Auth user
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromFirebaseUser(Map<String, dynamic> userData) {
    return AppUser(
      uid: userData['uid'] ?? '',
      name: userData['name'] ?? 'No Name',
      email: userData['email'] ?? 'No Email',
      photoUrl: userData['photoUrl'],
    );
  }
}

// Represents the Firestore profile
class Profile {
  final String? name;
  final String? rollNo;
  final String? interest;
  final String? bio;
  final String? year;
  final String? picture;

  Profile({
    this.name,
    this.rollNo,
    this.interest,
    this.bio,
    this.year,
    this.picture,
  });

  // Convert from Firestore map -> Profile
  factory Profile.fromMap(Map<String, dynamic> data) {
    return Profile(
      name: data['name'],
      rollNo: data['rollNo'],
      interest: data['interest'],
      bio: data['bio'],
      year: data['year'],
      picture: data['picture'],
    );
  }

  // Convert Profile -> Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNo': rollNo,
      'interest': interest,
      'bio': bio,
      'year': year,
      'picture': picture,
    };
  }
}
