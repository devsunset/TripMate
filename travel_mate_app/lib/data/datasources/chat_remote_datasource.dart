/// Firestore 기반 채팅 메시지 조회·발송. 실시간 스트림 + 채팅 기록 저장.
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_mate_app/domain/entities/chat_message.dart';
import 'package:travel_mate_app/data/models/chat_message_model.dart';
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ChatRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthorized: 로그인이 필요합니다.');
      }
      // senderId는 호출 측에서 백엔드 사용자 ID로 전달됨. 검증은 백엔드/보안 규칙에서 수행.

      final sentAt = DateTime.now();
      final message = ChatMessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        sentAt: sentAt,
      );

      final roomRef = _firestore.collection('chats').doc(chatRoomId);
      final messageRef = roomRef.collection('messages').doc();
      await _firestore.runTransaction((tx) async {
        tx.set(messageRef, message.toFirestore());
        tx.set(roomRef, {
          'participants': [senderId, receiverId],
          'lastMessage': content,
          'lastMessageAt': Timestamp.fromDate(sentAt),
          'lastMessageSenderId': senderId,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final sentAtRaw = data['sentAt'];
            final sentAt = sentAtRaw is Timestamp ? sentAtRaw.toDate() : DateTime.now();
            return ChatMessageModel(
              id: doc.id,
              senderId: _str(data['senderId']),
              receiverId: _str(data['receiverId']),
              content: _str(data['content']),
              sentAt: sentAt,
            );
          }).toList();
        });
  }

  static String _str(dynamic v) => v == null ? '' : (v is int ? v.toString() : v as String);

  /// 현재 사용자가 참여한 채팅방 목록 실시간 스트림. 기존 채팅 기록 포함.
  Stream<List<ChatRoomInfo>> getChatRooms(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final list = <ChatRoomInfo>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final participants = List<String>.from((data['participants'] as List<dynamic>?) ?? []);
            final otherId = participants.where((id) => id != currentUserId).firstOrNull ?? '';
            final lastAt = data['lastMessageAt'];
            final lastMessageAt = lastAt is Timestamp ? lastAt.toDate() : DateTime.now();
            list.add(ChatRoomInfo(
              chatRoomId: doc.id,
              otherParticipantId: otherId,
              lastMessage: _str(data['lastMessage']),
              lastMessageAt: lastMessageAt,
            ));
          }
          list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          return list;
        });
  }

  // Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
  //   // Implement logic to mark messages as read if needed
  // }
}
