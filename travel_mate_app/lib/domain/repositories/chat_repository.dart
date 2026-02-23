/// 채팅 메시지 스트림·발송·채팅방 목록·채팅 요청 추상 레포지토리.
import 'package:travel_mate_app/domain/entities/chat_message.dart';
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId);
  /// 내가 참여한 채팅방 목록(신청한/신청받은). API 기반.
  Future<List<ChatRoomInfo>> getChatRooms(String currentUserId);
  /// 채팅 요청(상대 이메일로 방 생성 또는 기존 반환).
  Future<ChatRoomInfo> createChatRoom(String partnerId);
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
  });
}
