/// 동행 검색 API 호출. GET /api/users/search
library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';

class CompanionSearchRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  CompanionSearchRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 동행 검색. 쿼리: destination, keyword, gender, ageRange, travelStyles, interests, limit, offset
  Future<List<UserProfileModel>> searchCompanions({
    String? destination,
    String? keyword,
    String? gender,
    String? ageRange,
    List<String>? travelStyles,
    List<String>? interests,
    int limit = 20,
    int offset = 0,
  }) async {
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null) throw Exception('로그인이 필요합니다.');

    final queryParams = <String, dynamic>{
      if (destination != null && destination.trim().isNotEmpty) 'destination': destination.trim(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (gender != null && gender.isNotEmpty && gender != '무관') 'gender': gender,
      if (ageRange != null && ageRange.isNotEmpty && ageRange != '무관') 'ageRange': ageRange,
      'limit': limit,
      'offset': offset,
    };
    if (travelStyles != null && travelStyles.isNotEmpty) {
      queryParams['travelStyles'] = travelStyles.join(',');
    }
    if (interests != null && interests.isNotEmpty) {
      queryParams['interests'] = interests.join(',');
    }

    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/api/users/search',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final list = data['users'] as List<dynamic>? ?? [];
      return list
          .map((e) => UserProfileModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw Exception('동행 검색 실패: ${response.statusCode}');
  }
}
