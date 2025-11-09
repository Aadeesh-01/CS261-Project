import 'package:flutter_test/flutter_test.dart';
import 'package:cs261_project/service/chat_service.dart';

void main() {
  group('ChatService', () {
    test('chatIdFor sorts deterministically', () {
      final service = ChatService();
      final id1 = service.chatIdFor('bUser', 'aUser');
      final id2 = service.chatIdFor('aUser', 'bUser');
      expect(id1, 'aUser_bUser');
      expect(id2, id1);
    });
  });
}
