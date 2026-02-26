/// 사용자 프로필 레포지토리 구현 (웹). dart:io 미사용. 이미지 업로드 시 예외.
library;
import 'package:travel_mate_app/data/datasources/profile_remote_datasource.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<void> createUserProfile(UserProfile userProfile) async {
    if (userProfile is UserProfileModel) {
      await remoteDataSource.createUserProfile(userProfile);
    } else {
      await remoteDataSource.createUserProfile(UserProfileModel(
        userId: userProfile.userId,
        nickname: userProfile.nickname,
        bio: userProfile.bio,
        profileImageUrl: userProfile.profileImageUrl,
        gender: userProfile.gender,
        ageRange: userProfile.ageRange,
        travelStyles: userProfile.travelStyles,
        interests: userProfile.interests,
        preferredDestinations: userProfile.preferredDestinations,
      ));
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile userProfile) async {
    if (userProfile is UserProfileModel) {
      await remoteDataSource.updateUserProfile(userProfile);
    } else {
      await remoteDataSource.updateUserProfile(UserProfileModel(
        userId: userProfile.userId,
        nickname: userProfile.nickname,
        bio: userProfile.bio,
        profileImageUrl: userProfile.profileImageUrl,
        gender: userProfile.gender,
        ageRange: userProfile.ageRange,
        travelStyles: userProfile.travelStyles,
        interests: userProfile.interests,
        preferredDestinations: userProfile.preferredDestinations,
      ));
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    await remoteDataSource.deleteUserProfile(userId);
  }

  @override
  Future<void> deleteUserAccount(String userId) async {
    await remoteDataSource.deleteUserAccount(userId);
  }

  @override
  Future<String> uploadProfileImage(String userId, String imagePath) async {
    return await remoteDataSource.uploadProfileImage(userId, imagePath);
  }
}
