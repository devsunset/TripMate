/// 프로필 API 호출 (웹). dart:io 미사용. 이미지 업로드는 웹에서 미지원 시 예외.
library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';

class ProfileRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  ProfileRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  Future<String> uploadProfileImage(String userId, dynamic image) async {
    throw UnsupportedError(
      '프로필 이미지 업로드는 웹에서 지원되지 않습니다. 모바일 앱을 사용하세요.',
    );
  }

  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userId)}/profile',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      // 200: 기존 프로필, 201: 최초 로그인 시 백엔드가 자동 생성한 프로필
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserProfileModel.fromJson(response.data['userProfile']);
      }
      throw Exception('Failed to load user profile: ${response.data}');
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<void> createUserProfile(UserProfileModel userProfile) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userProfile.userId)}/profile',
        data: userProfile.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(UserProfileModel userProfile) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final response = await _dio.patch(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userProfile.userId)}/profile',
        data: userProfile.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final response = await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userId)}/profile',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to delete user profile: ${e.toString()}');
    }
  }

  /// 계정 삭제(백엔드 DB + Firebase Auth). 본인 userId(백엔드 사용자 ID) 필요.
  Future<void> deleteUserAccount(String userId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final response = await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userId)}',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete account: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
