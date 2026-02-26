/// 게시글 API 호출 및 백엔드 이미지 업로드.
library;
import 'dart:io' if (dart.library.html) 'package:travel_mate_app/core/io_stub/file_stub.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/data/models/post_model.dart';

class PostRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  PostRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 게시글 이미지를 백엔드에 업로드하고 반환된 imageUrl을 전달합니다.
  Future<String> uploadPostImage(String userId, File imageFile) async {
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
        '${AppConstants.apiBaseUrl}/api/upload/post',
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

  // Get posts from backend API
  Future<List<PostModel>> getPosts() async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/posts', // Replace with your backend URL
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode == 200) {
        return (response.data['posts'] as List)
            .map((json) => PostModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load posts: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get posts: ${e.toString()}');
    }
  }

  // Get single post from backend API
  Future<PostModel> getPost(String postId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/posts/$postId',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode == 200) {
        return PostModel.fromJson(response.data['post']);
      } else {
        throw Exception('Failed to load post: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get post: ${e.toString()}');
    }
  }

  // Create post in backend API
  Future<void> createPost(PostModel post) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/api/posts', // Replace with your backend URL
        data: post.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create post: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  // Update post in backend API
  Future<void> updatePost(PostModel post) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.patch(
        '${AppConstants.apiBaseUrl}/api/posts/${post.id}', // Replace with your backend URL
        data: post.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update post: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to update post: ${e.toString()}');
    }
  }

  // Delete post in backend API
  Future<void> deletePost(String postId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/posts/$postId',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete post: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }
}
