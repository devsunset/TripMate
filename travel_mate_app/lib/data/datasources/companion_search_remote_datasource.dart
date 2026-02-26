/// 동행 검색 API 호출. GET /api/users/search
library;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';

class CompanionSearchRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  CompanionSearchRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 동행 검색. 쿼리: destination, keyword, gender, ageRange, travelStyles, interests, limit, offset
  /// 실제 요청 파라미터와 응답 결과는 디버그 로그로 출력됨. total 포함 반환.
  Future<PaginatedResult<UserProfileModel>> searchCompanions({
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

    if (kDebugMode) {
      debugPrint('[동행 검색] 요청 쿼리: $queryParams');
      debugPrint('[동행 검색] URL: ${AppConstants.apiBaseUrl}/api/users/search');
    }

    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/api/users/search',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>?;
      final total = (data?['total'] as num?)?.toInt() ?? 0;
      final list = data?['users'] as List<dynamic>? ?? [];
      final results = list
          .map((e) => UserProfileModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (kDebugMode) {
        debugPrint('[동행 검색] 응답: total=$total, returned=${results.length}, limit=$limit, offset=$offset');
        if (results.isNotEmpty) {
          debugPrint('[동행 검색] 결과 샘플(닉네임): ${results.take(3).map((u) => u.nickname).join(", ")}');
        }
      }

      return PaginatedResult<UserProfileModel>(items: results, total: total);
    }
    throw Exception('동행 검색 실패: ${response.statusCode}');
  }
}
