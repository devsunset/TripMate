/// 일정 목록/단건 조회·생성·수정·삭제·이미지 업로드 추상 레포지토리.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';

abstract class ItineraryRepository {
  /// 페이징: limit, offset 기본 20, 0. total 포함 반환.
  Future<PaginatedResult<Itinerary>> getItineraries({int limit = 20, int offset = 0});
  Future<Itinerary> getItinerary(String itineraryId);
  Future<void> createItinerary(Itinerary itinerary);
  Future<void> updateItinerary(Itinerary itinerary);
  Future<void> deleteItinerary(String itineraryId);
  Future<String> uploadItineraryImage(String userId, String imagePath);
}
