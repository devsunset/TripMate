/// 일정 목록 조회 유스케이스. 페이징 지원.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class GetItineraries {
  final ItineraryRepository repository;

  GetItineraries(this.repository);

  Future<PaginatedResult<Itinerary>> execute({int limit = 20, int offset = 0}) async {
    return await repository.getItineraries(limit: limit, offset: offset);
  }
}