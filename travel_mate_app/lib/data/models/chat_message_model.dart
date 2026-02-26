/// 채팅 메시지 DTO. Firestore 문서·[ChatMessage] 엔티티 변환.
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_mate_app/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.sentAt,
  });

  static String _toString(dynamic v) => v == null ? '' : (v is int ? v.toString() : v as String);

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    final sentAtRaw = data?['sentAt'];
    final sentAt = sentAtRaw is Timestamp ? sentAtRaw.toDate() : DateTime.now();
    return ChatMessageModel(
      id: snapshot.id,
      senderId: _toString(data?['senderId']),
      receiverId: _toString(data?['receiverId']),
      content: _toString(data?['content']),
      sentAt: sentAt,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      senderId: entity.senderId,
      receiverId: entity.receiverId,
      content: entity.content,
      sentAt: entity.sentAt,
    );
  }
}
