import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  final String instituteId;
  const InboxScreen({super.key, required this.instituteId});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  Future<void> _startChat(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    Future<Map<String, String>?> pickFromPath(
      CollectionReference<Map<String, dynamic>> col,
    ) async {
      final snap = await col.limit(50).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = (data['uid'] as String?) ?? doc.id;
        if (uid == currentUserId) continue;
        final name =
            (data['name'] as String?) ?? (data['email'] as String?) ?? 'User';
        return {'uid': uid, 'name': name};
      }
      return null;
    }

    // 1) Institute participants
    final fromInstituteParticipants = await pickFromPath(FirebaseFirestore
        .instance
        .collection('institutes')
        .doc(instituteId)
        .collection('participants')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (m, _) => m,
        ));

    // 2) Institute profiles (fallback)
    final fromInstituteProfiles = fromInstituteParticipants ??
        await pickFromPath(FirebaseFirestore.instance
            .collection('institutes')
            .doc(instituteId)
            .collection('profiles')
            .withConverter<Map<String, dynamic>>(
              fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
              toFirestore: (m, _) => m,
            ));

    // 3) Root participants (fallback for older data)
    final fromRootParticipants = fromInstituteProfiles ??
        await pickFromPath(FirebaseFirestore.instance
            .collection('participants')
            .withConverter<Map<String, dynamic>>(
              fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
              toFirestore: (m, _) => m,
            ));

    // 4) Root profiles (last fallback)
    final chosen = fromRootParticipants ??
        await pickFromPath(FirebaseFirestore.instance
            .collection('profiles')
            .withConverter<Map<String, dynamic>>(
              fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
              toFirestore: (m, _) => m,
            ));

    if (chosen == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No other users found. Ask an admin to add participants.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: chosen['uid']!,
          otherUserName: chosen['name']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No chats yet'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Start a chat'),
                    onPressed: () => _startChat(context),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId =
                  participants.firstWhere((id) => id != currentUserId);
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('institutes')
                    .doc(instituteId)
                    .collection('profiles')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                    );
                  }
                  if (!userSnapshot.hasData ||
                      userSnapshot.data?.data() == null) {
                    return ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_off)),
                      title: const Text('User not found'),
                      subtitle: Text(chat['lastMessage']['text'] ?? ''),
                    );
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final lastMessageData =
                      chat['lastMessage'] as Map<String, dynamic>?;
                  final lastMessageText = lastMessageData?['text'] ?? '';
                  final lastMessageTimestamp =
                      lastMessageData?['lastMessageTimestamp'] as Timestamp?;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTime(lastMessageTimestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: otherUserId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
