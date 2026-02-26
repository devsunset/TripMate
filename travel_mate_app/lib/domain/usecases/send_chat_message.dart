/// 채팅 메시지 발송 유스케이스.
library;
import 'package:travel_mate_app/domain/repositories/chat_repository.dart';

class SendChatMessage {
  final ChatRepository repository;

  SendChatMessage(this.repository);

  Future<void> execute({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    return await repository.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
    );
  }
}
