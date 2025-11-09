import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  // The image is no longer required as we will use initials for consistency
  // final String? otherUserImage;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    // required this.otherUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String _chatId; // Changed to non-nullable

  @override
  void initState() {
    super.initState();
    // --- IMPROVEMENT 1: Use Composite ID ---
    // Generate the chat ID immediately and deterministically.
    final currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, widget.otherUserId];
    ids.sort(); // Sort the IDs to ensure the chatId is always the same for both users
    _chatId = ids.join('_');
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUserId = _auth.currentUser!.uid;
    final messageTimestamp = FieldValue.serverTimestamp();

    // Create the message data
    final messageData = {
      'senderId': currentUserId,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': messageTimestamp,
    };

    // Create the chat data for the inbox preview
    final chatData = {
      'lastMessage': {
        'text': text,
        'senderId': currentUserId,
        'lastMessageTimestamp': messageTimestamp,
      },
      'lastMessageTimestamp': messageTimestamp, // For ordering the inbox
      'participants': [_chatId.split('_')[0], _chatId.split('_')[1]],
    };

    // --- IMPROVEMENT 2: Use a WriteBatch for Atomic Operations ---
    final batch = _firestore.batch();

    // 1. Add the new message to the messages subcollection
    final messageDocRef = _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .doc();
    batch.set(messageDocRef, messageData);

    // 2. Update the parent chat document with the latest message summary
    final chatDocRef = _firestore.collection('chats').doc(_chatId);
    batch.set(chatDocRef, chatData, SetOptions(merge: true));

    // Commit the batch
    await batch.commit();

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            // --- IMPROVEMENT 3: UI Consistency ---
            // Use user's initial instead of a network image.
            CircleAvatar(
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId) // Directly access the chat document
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say hello!"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(width: 0, style: BorderStyle.none),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
