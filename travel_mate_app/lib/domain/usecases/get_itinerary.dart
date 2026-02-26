/// 일정 단건 조회 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class GetItinerary {
  final ItineraryRepository repository;

  GetItinerary(this.repository);

  Future<Itinerary> execute(String itineraryId) async {
    return await repository.getItinerary(itineraryId);
  }
}