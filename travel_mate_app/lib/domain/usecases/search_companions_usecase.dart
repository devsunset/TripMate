/// 동행 검색 유스케이스
library;
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/repositories/companion_repository.dart';

class SearchCompanionsUsecase {
  final CompanionRepository _repository;

  SearchCompanionsUsecase(this._repository);

  Future<List<UserProfile>> execute({
    String? destination,
    String? keyword,
    String? gender,
    String? ageRange,
    List<String>? travelStyles,
    List<String>? interests,
    int limit = 20,
    int offset = 0,
  }) async {
    return _repository.searchCompanions(
      destination: destination,
      keyword: keyword,
      gender: gender,
      ageRange: ageRange,
      travelStyles: travelStyles,
      interests: interests,
      limit: limit,
      offset: offset,
    );
  }
}
