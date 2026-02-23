/// 채팅방 목록용 엔티티(채팅방 ID, 상대 ID, 마지막 메시지·시각, 신청한/신청받은 구분).
import 'package:equatable/equatable.dart';

class ChatRoomInfo extends Equatable {
  final String chatRoomId;
  final String otherParticipantId;
  final String lastMessage;
  final DateTime lastMessageAt;
  /// true: 내가 채팅을 신청한 방, false: 상대가 신청한(신청받은) 방
  final bool isRequestedByMe;
  final String? partnerNickname;
  final String? partnerProfileImageUrl;

  const ChatRoomInfo({
    required this.chatRoomId,
    required this.otherParticipantId,
    required this.lastMessage,
    required this.lastMessageAt,
    this.isRequestedByMe = false,
    this.partnerNickname,
    this.partnerProfileImageUrl,
  });

  @override
  List<Object?> get props => [
        chatRoomId,
        otherParticipantId,
        lastMessage,
        lastMessageAt,
        isRequestedByMe,
        partnerNickname,
        partnerProfileImageUrl,
      ];
}
