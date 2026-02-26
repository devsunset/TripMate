/// 일정 대표 이미지 업로드 유스케이스. 업로드된 이미지 URL 반환.
library;
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';

class UploadItineraryImage {
  final ItineraryRepository repository;

  UploadItineraryImage(this.repository);

  Future<String> execute(String userId, String imagePath) async {
    return await repository.uploadItineraryImage(userId, imagePath);
  }
}