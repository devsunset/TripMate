/// 프로필 이미지 업로드 유스케이스. 업로드된 이미지 URL 반환.
library;
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';

class UploadProfileImage {
  final UserProfileRepository repository;

  UploadProfileImage(this.repository);

  Future<String> execute(String userId, String imagePath) async {
    return await repository.uploadProfileImage(userId, imagePath);
  }
}