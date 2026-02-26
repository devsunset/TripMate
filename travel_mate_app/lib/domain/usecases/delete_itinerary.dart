/// 일정 삭제 유스케이스.
library;
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class DeleteItinerary {
  final ItineraryRepository repository;

  DeleteItinerary(this.repository);

  Future<void> execute(String itineraryId) async {
    return await repository.deleteItinerary(itineraryId);
  }
}