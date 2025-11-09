# cs261_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Created by:
Aadeesh Surana,
Lokesh Prajapat, 
Nitin Raj Singh, 
Mehul Mehra, 
Archan Dave and
Ayush Bagdai

## Messaging Feature

This app includes a simple 1:1 messaging feature built on Cloud Firestore.

Data model:
- Collection `chats/{chatId}`
	- participants: [userId1, userId2]
	- lastMessageTimestamp: server timestamp (for ordering)
	- lastMessage: { text, senderId, lastMessageTimestamp }
	- Subcollection `messages/{messageId}`
		- senderId, receiverId, text, timestamp

chatId format:
- Deterministic by sorting two user IDs and joining with `_`, e.g. `userA_userB`.

UI:
- Inbox lists chats involving the current user ordered by `lastMessageTimestamp`.
- Chat screen streams messages in descending order and allows sending new messages.

Code:
- Service: `lib/service/chat_service.dart`
- Model: `lib/model/message_model.dart`
- Screens:
	- Inbox: `lib/screen/message/inbox_screen.dart`
	- Chat: `lib/screen/message/chat_screen.dart`