/// 사용자 프로필 조회·생성·수정·이미지 업로드 추상 레포지토리.
library;
import 'package:travel_mate_app/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
  Future<void> createUserProfile(UserProfile userProfile);
  Future<void> updateUserProfile(UserProfile userProfile);
  Future<void> deleteUserProfile(String userId);
  /// 계정 삭제(백엔드 DB·Firebase Auth). userId는 백엔드 사용자 ID.
  Future<void> deleteUserAccount(String userId);
  /// 업로드된 이미지 URL 반환
  Future<String> uploadProfileImage(String userId, String imagePath);
}