/// 일정 목록 조회 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class GetItineraries {
  final ItineraryRepository repository;

  GetItineraries(this.repository);

  Future<List<Itinerary>> execute() async {
    return await repository.getItineraries();
  }
}