/// 동행 검색 추상 레포지토리
library;
import 'package:travel_mate_app/domain/entities/user_profile.dart';

abstract class CompanionRepository {
  Future<List<UserProfile>> searchCompanions({
    String? destination,
    String? keyword,
    String? gender,
    String? ageRange,
    List<String>? travelStyles,
    List<String>? interests,
    int limit,
    int offset,
  });
}