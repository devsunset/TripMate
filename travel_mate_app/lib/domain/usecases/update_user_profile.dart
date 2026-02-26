/// 사용자 프로필 수정 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';

class UpdateUserProfile {
  final UserProfileRepository repository;

  UpdateUserProfile(this.repository);

  Future<void> execute(UserProfile userProfile) async {
    return await repository.updateUserProfile(userProfile);
  }
}