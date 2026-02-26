/// 동행 검색 레포지토리 구현. API 호출 후 UserProfile 리스트 반환.
library;
import 'package:travel_mate_app/data/datasources/companion_search_remote_datasource.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/repositories/companion_repository.dart';

class CompanionRepositoryImpl implements CompanionRepository {
  final CompanionSearchRemoteDataSource _remoteDataSource;

  CompanionRepositoryImpl({required CompanionSearchRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaginatedResult<UserProfile>> searchCompanions({
    String? destination,
    String? keyword,
    String? gender,
    String? ageRange,
    List<String>? travelStyles,
    List<String>? interests,
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _remoteDataSource.searchCompanions(
      destination: destination,
      keyword: keyword,
      gender: gender,
      ageRange: ageRange,
      travelStyles: travelStyles,
      interests: interests,
      limit: limit,
      offset: offset,
    );
    return PaginatedResult<UserProfile>(items: result.items, total: result.total);
  }
}
