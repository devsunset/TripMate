/// 1:1 쪽지 엔티티(발신자, 수신자, 내용, 읽음 여부, 전송 시각).
library;
import 'package:equatable/equatable.dart';

class PrivateMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const PrivateMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        content,
        sentAt,
        isRead,
      ];
}