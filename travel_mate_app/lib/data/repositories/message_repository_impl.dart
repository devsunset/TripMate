/// 1:1 쪽지 레포지토리 구현. 원격 데이터소스 위임.
library;
import 'package:travel_mate_app/data/datasources/message_remote_datasource.dart';
import 'package:travel_mate_app/domain/repositories/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> sendPrivateMessage({
    required String receiverId,
    required String content,
  }) async {
    return await remoteDataSource.sendPrivateMessage(
      receiverId: receiverId,
      content: content,
    );
  }
}
