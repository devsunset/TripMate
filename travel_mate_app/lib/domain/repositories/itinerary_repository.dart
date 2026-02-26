/// 일정 목록/단건 조회·생성·수정·삭제·이미지 업로드 추상 레포지토리.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';

abstract class ItineraryRepository {
  Future<List<Itinerary>> getItineraries();
  Future<Itinerary> getItinerary(String itineraryId);
  Future<void> createItinerary(Itinerary itinerary);
  Future<void> updateItinerary(Itinerary itinerary);
  Future<void> deleteItinerary(String itineraryId);
  Future<String> uploadItineraryImage(String userId, String imagePath);
}
