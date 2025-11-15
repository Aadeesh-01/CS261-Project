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
  // Alumni-specific fields
  final String? company;
  final String? position;
  final String? city;
  final String? linkedin;
  // Student-specific fields
  final String? semester;
  final String? branch;

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
    this.company,
    this.position,
    this.city,
    this.linkedin,
    this.semester,
    this.branch,
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
      company: json['company'],
      position: json['position'],
      city: json['city'],
      linkedin: json['linkedin'],
      semester: json['semester'],
      branch: json['branch'],
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
      'company': company,
      'position': position,
      'city': city,
      'linkedin': linkedin,
      'semester': semester,
      'branch': branch,
      'isProfileComplete': isProfileComplete,
    };
  }
}
