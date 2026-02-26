/// 일정 수정 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class UpdateItinerary {
  final ItineraryRepository repository;

  UpdateItinerary(this.repository);

  Future<void> execute(Itinerary itinerary) async {
    return await repository.updateItinerary(itinerary);
  }
}