class Profile {
  final String? docId;
  final String? name;
  final String? rollNo;
  final String? interest;
  final String? bio;
  final String? year;
  final String? picture;
  final String? role;
  final bool? isProfileComplete;

  Profile({
    this.docId,
    this.name,
    this.rollNo,
    this.interest,
    this.bio,
    this.year,
    this.picture,
    this.role,
    this.isProfileComplete,
  });

  factory Profile.fromJson(Map<String, dynamic> json, String documentId) {
    return Profile(
      docId: documentId,
      name: json['name'],
      rollNo: json['rollNo'],
      interest: json['interest'],
      bio: json['bio'],
      year: json['year'],
      picture: json['picture'],
      role: json['role'],
      isProfileComplete: json['isProfileComplete'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rollNo': rollNo,
      'interest': interest,
      'bio': bio,
      'year': year,
      'picture': picture,
      'isProfileComplete': true,
    };
  }
}
