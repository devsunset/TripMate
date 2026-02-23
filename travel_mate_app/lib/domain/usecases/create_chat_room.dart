/// 채팅 요청(상대에게 채팅하기) 유스케이스. 방 생성 또는 기존 방 반환.
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';
import 'package:travel_mate_app/domain/repositories/chat_repository.dart';

class CreateChatRoom {
  final ChatRepository repository;

  CreateChatRoom(this.repository);

  Future<ChatRoomInfo> execute(String partnerId) {
    return repository.createChatRoom(partnerId);
  }
}
