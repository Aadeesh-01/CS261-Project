class Profile {
  final String? docId;
  final String? uid;
  final String? name;
  final String? rollNo;
  final String? year;
  final String? interest;
  final String? bio;
  final String? picture;
  final String? role;
  final bool isProfileComplete;

  Profile({
    this.docId,
    this.uid,
    this.name,
    this.rollNo,
    this.year,
    this.interest,
    this.bio,
    this.picture,
    this.role,
    this.isProfileComplete = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json, String docId) {
    return Profile(
      docId: docId,
      uid: json['uid'],
      name: json['name'],
      rollNo: json['rollNo'],
      year: json['year'],
      interest: json['interest'],
      bio: json['bio'],
      picture: json['picture'],
      role: json['role'],
      isProfileComplete: json['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'rollNo': rollNo,
      'year': year,
      'interest': interest,
      'bio': bio,
      'picture': picture,
      'role': role,
      'isProfileComplete': isProfileComplete,
    };
  }
}
