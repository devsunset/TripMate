/// 여행 일정 엔티티(제목, 설명, 기간, 이미지 URL, 지도 데이터).
import 'package:equatable/equatable.dart';

class Itinerary extends Equatable {
  final String id;
  final String authorId;
  /// 표시용 작성자 닉네임 (API에서 Author.UserProfile.nickname 등으로 내려줌).
  final String? authorNickname;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> imageUrls;
  final List<Map<String, double>> mapData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Itinerary({
    required this.id,
    required this.authorId,
    this.authorNickname,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.imageUrls = const [],
    this.mapData = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorNickname,
        title,
        description,
        startDate,
        endDate,
        imageUrls,
        mapData,
        createdAt,
        updatedAt,
      ];
}