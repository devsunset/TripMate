/// 사용자 프로필 레포지토리 구현 (IO/모바일). dart:io 사용.
library;
import 'dart:io';

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
    await remoteDataSource.createUserProfile(UserProfileModel.fromEntity(userProfile));
  }

  @override
  Future<void> updateUserProfile(UserProfile userProfile) async {
    await remoteDataSource.updateUserProfile(UserProfileModel.fromEntity(userProfile));
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
    return await remoteDataSource.uploadProfileImage(userId, File(imagePath));
  }
}
