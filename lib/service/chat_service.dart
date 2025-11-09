import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Deterministic chatId from two userIds (sorted join)
  String chatIdFor(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final messageTimestamp = FieldValue.serverTimestamp();

    final messageData = <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text.trim(),
      'timestamp': messageTimestamp,
    };

    final lastMessage = <String, dynamic>{
      'text': text.trim(),
      'senderId': senderId,
      'lastMessageTimestamp': messageTimestamp,
    };

    final chatData = <String, dynamic>{
      'lastMessage': lastMessage,
      'lastMessageTimestamp': messageTimestamp,
      'participants': chatId.split('_'),
    };

    final batch = _firestore.batch();
    final messageDocRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final chatDocRef = _firestore.collection('chats').doc(chatId);

    batch.set(messageDocRef, messageData);
    batch.set(chatDocRef, chatData, SetOptions(merge: true));

    await batch.commit();
  }
}
