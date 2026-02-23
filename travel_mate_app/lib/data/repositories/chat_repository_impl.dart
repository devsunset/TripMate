/// 채팅 레포지토리 구현. 목록·채팅 요청은 API, 메시지는 Firestore.
import 'package:travel_mate_app/data/datasources/chat_remote_datasource.dart';
import 'package:travel_mate_app/data/datasources/chat_api_datasource.dart';
import 'package:travel_mate_app/domain/entities/chat_message.dart';
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';
import 'package:travel_mate_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatApiDataSource apiDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.apiDataSource,
  });

  @override
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return remoteDataSource.getChatMessages(chatRoomId);
  }

  @override
  Future<List<ChatRoomInfo>> getChatRooms(String currentUserId) {
    return apiDataSource.getChatRooms(currentUserId);
  }

  @override
  Future<ChatRoomInfo> createChatRoom(String partnerId) {
    return apiDataSource.createChatRoom(partnerId);
  }

  @override
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    return await remoteDataSource.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
    );
  }
}
