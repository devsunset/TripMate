/// 사용자 프로필 단건 조회 유스케이스
library;
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';

class GetUserProfile {
  final UserProfileRepository repository;

  GetUserProfile(this.repository);

  Future<UserProfile> execute(String userId) async {
    return await repository.getUserProfile(userId);
  }
}