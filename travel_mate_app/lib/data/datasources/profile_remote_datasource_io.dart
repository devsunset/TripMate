/// 프로필 API 호출 및 백엔드 프로필 이미지 업로드 (IO/모바일).
library;
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  /// image: String(경로) 또는 File. 웹에서는 사용하지 않음.
  Future<String> uploadProfileImage(String userId, dynamic image) async {
    final File imageFile = image is String ? File(image) : image as File;
    try {
      final filePath = imageFile.absolute.path;
      final targetPath = '${filePath}_compressed.jpg';

      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );

      if (compressedImage == null) {
        throw Exception('Image compression failed');
      }

      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) throw Exception('User not authenticated.');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(compressedImage.path, filename: 'image.jpg'),
      });

      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/api/upload/profile',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode == 200 && response.data['imageUrl'] != null) {
        return response.data['imageUrl'] as String;
      }
      throw Exception('Failed to upload image: ${response.data}');
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userId)}/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      // 200: 기존 프로필, 201: 최초 로그인 시 백엔드가 자동 생성한 프로필
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserProfileModel.fromJson(response.data['userProfile']);
      } else {
        throw Exception('Failed to load user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<void> createUserProfile(UserProfileModel userProfile) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userProfile.userId)}/profile',
        data: userProfile.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
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
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.patch(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userProfile.userId)}/profile',
        data: userProfile.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
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
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/users/${Uri.encodeComponent(userId)}/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
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
