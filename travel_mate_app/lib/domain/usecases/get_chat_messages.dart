/// 채팅 메시지 스트림 조회 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/chat_message.dart';
import 'package:travel_mate_app/domain/repositories/chat_repository.dart';

class GetChatMessages {
  final ChatRepository repository;

  GetChatMessages(this.repository);

  Stream<List<ChatMessage>> execute(String chatRoomId) {
    return repository.getChatMessages(chatRoomId);
  }
}
