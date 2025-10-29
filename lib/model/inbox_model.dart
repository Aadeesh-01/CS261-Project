import 'package:cloud_firestore/cloud_firestore.dart';

class Inbox {
  final String id; // The document ID of the chat
  final List<String> participants; // List of participant UIDs
  final String otherUserUid; // The UID of the other user in the chat
  final String lastMessageText;
  final DateTime lastMessageTimestamp;

  Inbox({
    required this.id,
    required this.participants,
    required this.otherUserUid,
    required this.lastMessageText,
    required this.lastMessageTimestamp,
  });

  // Factory constructor to create an Inbox object from a Firestore document
  factory Inbox.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    Map<String, dynamic> data = doc.data()!;

    // Find the other user's UID from the participants list
    List<String> participants = List<String>.from(data['participants'] ?? []);
    String otherUserUid = participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => '', // Fallback in case something goes wrong
    );

    // Extract last message details
    final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

    return Inbox(
      id: doc.id,
      participants: participants,
      otherUserUid: otherUserUid,
      lastMessageText: lastMessageData?['text'] ?? 'No messages yet.',
      lastMessageTimestamp:
          (data['lastMessageTimestamp'] as Timestamp? ?? Timestamp.now())
              .toDate(),
    );
  }
}
