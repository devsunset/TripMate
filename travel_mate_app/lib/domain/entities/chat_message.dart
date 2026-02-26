/// 채팅 메시지 엔티티(발신자, 내용, 전송 시각 등).
library;
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId; // Or chatRoomId
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ChatMessage(
      id: snapshot.id,
      senderId: data?['senderId'],
      receiverId: data?['receiverId'], // Or chatRoomId
      content: data?['content'],
      sentAt: (data?['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId, // Or chatRoomId
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, content, sentAt];
}
