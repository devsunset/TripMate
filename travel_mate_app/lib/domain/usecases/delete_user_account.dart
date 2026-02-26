/// 계정 삭제 유스케이스 (백엔드 DB·Firebase Auth 삭제)
library;
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';

class DeleteUserAccount {
  final UserProfileRepository repository;

  DeleteUserAccount(this.repository);

  Future<void> execute(String userId) async {
    await repository.deleteUserAccount(userId);
  }
}
