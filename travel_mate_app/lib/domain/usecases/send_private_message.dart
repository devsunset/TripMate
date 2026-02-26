/// 1:1 쪽지 발송 유스케이스.
library;
import 'package:travel_mate_app/domain/repositories/message_repository.dart';

class SendPrivateMessage {
  final MessageRepository repository;

  SendPrivateMessage(this.repository);

  Future<void> execute({
    required String receiverId,
    required String content,
  }) async {
    return await repository.sendPrivateMessage(
      receiverId: receiverId,
      content: content,
    );
  }
}