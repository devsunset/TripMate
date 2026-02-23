/// 채팅방 목록·채팅 요청 API (백엔드 GET /api/chat/rooms, POST /api/chat/room).
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';

class ChatApiDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  ChatApiDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 내가 참여한 채팅방 목록 (신청한/신청받은). GET /api/chat/rooms
  Future<List<ChatRoomInfo>> getChatRooms(String currentUserId) async {
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null) throw Exception('로그인이 필요합니다.');

    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/api/chat/rooms',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final list = data['chatRooms'] as List<dynamic>? ?? [];
      return list
          .map((e) => _chatRoomInfoFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw Exception('채팅 목록 조회 실패: ${response.statusCode}');
  }

  /// 채팅 요청(방 생성 또는 기존 반환). POST /api/chat/room body: { partnerId }
  Future<ChatRoomInfo> createChatRoom(String partnerId) async {
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null) throw Exception('로그인이 필요합니다.');

    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/api/chat/room',
      data: {'partnerId': partnerId},
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final chatRoomId = data['chatRoomId'] as String? ?? '';
      return ChatRoomInfo(
        chatRoomId: chatRoomId,
        otherParticipantId: partnerId,
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        isRequestedByMe: data['isRequestedByMe'] as bool? ?? true,
        partnerNickname: null,
        partnerProfileImageUrl: null,
      );
    }
    throw Exception('채팅 요청 실패: ${response.statusCode}');
  }

  static ChatRoomInfo _chatRoomInfoFromJson(Map<String, dynamic> json) {
    final lastAt = json['lastMessageAt'];
    DateTime lastMessageAt = DateTime.now();
    if (lastAt != null) {
      if (lastAt is String) lastMessageAt = DateTime.tryParse(lastAt) ?? lastMessageAt;
    }
    return ChatRoomInfo(
      chatRoomId: json['chatRoomId'] as String? ?? '',
      otherParticipantId: json['partnerEmail'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: lastMessageAt,
      isRequestedByMe: json['isRequestedByMe'] as bool? ?? false,
      partnerNickname: json['partnerNickname'] as String?,
      partnerProfileImageUrl: json['partnerProfileImageUrl'] as String?,
    );
  }
}
