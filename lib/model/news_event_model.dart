import 'package:cloud_firestore/cloud_firestore.dart';

class NewsEventPost {
  final String id;
  final String title;
  final String description;
  final String type; // "news", "event", "experience"
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String imageUrl;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;

  NewsEventPost({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.imageUrl,
    required this.likes,
    required this.comments,
  });

  factory NewsEventPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsEventPost(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'news',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
    };
  }
}
