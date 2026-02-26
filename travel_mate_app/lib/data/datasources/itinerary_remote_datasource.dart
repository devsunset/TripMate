/// 일정 API 호출 및 백엔드 일정 이미지 업로드.
library;
import 'dart:io' if (dart.library.html) 'package:travel_mate_app/core/io_stub/file_stub.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/data/models/itinerary_model.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';

class ItineraryRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  ItineraryRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 일정 이미지를 백엔드에 업로드하고 반환된 imageUrl을 전달합니다.
  Future<String> uploadItineraryImage(String userId, File imageFile) async {
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
        '${AppConstants.apiBaseUrl}/api/upload/itinerary',
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

  /// 일정 목록 페이징. limit, offset 기본 20, 0. total 포함 반환.
  Future<PaginatedResult<ItineraryModel>> getItineraries({int limit = 20, int offset = 0}) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/itineraries',
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final total = (data?['total'] as num?)?.toInt() ?? 0;
        final list = (data?['itineraries'] as List?)
                ?.map((json) => ItineraryModel.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return PaginatedResult<ItineraryModel>(items: list, total: total);
      } else {
        throw Exception('Failed to load itineraries: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get itineraries: ${e.toString()}');
    }
  }

  // Get single itinerary from backend API
  Future<ItineraryModel> getItinerary(String itineraryId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/api/itineraries/$itineraryId', // Replace with your backend URL
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode == 200) {
        return ItineraryModel.fromJson(response.data['itinerary']);
      } else {
        throw Exception('Failed to load itinerary: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get itinerary: ${e.toString()}');
    }
  }

  // Create itinerary in backend API
  Future<void> createItinerary(ItineraryModel itinerary) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/api/itineraries', // Replace with your backend URL
        data: itinerary.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create itinerary: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to create itinerary: ${e.toString()}');
    }
  }

  // Update itinerary in backend API
  Future<void> updateItinerary(ItineraryModel itinerary) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.patch(
        '${AppConstants.apiBaseUrl}/api/itineraries/${itinerary.id}', // Replace with your backend URL
        data: itinerary.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update itinerary: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to update itinerary: ${e.toString()}');
    }
  }

  // Delete itinerary in backend API
  Future<void> deleteItinerary(String itineraryId) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _dio.delete(
        '${AppConstants.apiBaseUrl}/api/itineraries/$itineraryId', // Replace with your backend URL
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete itinerary: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to delete itinerary: ${e.toString()}');
    }
  }
}
