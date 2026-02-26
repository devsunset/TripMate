/// 일정 DTO. JSON 직렬화 및 [Itinerary] 엔티티 확장.
/// 백엔드(Sequelize)는 id, authorId 등을 int로 보낼 수 있으므로 int/String 모두 파싱.
library;
import 'package:travel_mate_app/domain/entities/itinerary.dart';

class ItineraryModel extends Itinerary {
  const ItineraryModel({
    required super.id,
    required super.authorId,
    super.authorNickname,
    required super.title,
    required super.description,
    required super.startDate,
    required super.endDate,
    super.imageUrls,
    super.mapData,
    required super.createdAt,
    required super.updatedAt,
  });

  static String _toString(dynamic v) => v == null ? '' : (v is int ? v.toString() : v as String);
  static DateTime _toDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.parse(v.toString());
  }
  static List<String> _toStringList(List<dynamic>? list) =>
      list?.map((e) => e == null ? '' : (e is int ? e.toString() : e as String)).toList() ?? const [];
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
  static List<Map<String, double>> _toMapDataList(List<dynamic>? list) {
    if (list == null) return const [];
    return list.map((e) {
      if (e is! Map) return <String, double>{};
      return Map<String, double>.from(
        e.map((k, v) => MapEntry(k.toString(), _toDouble(v))),
      );
    }).toList();
  }

  static String? _authorNicknameFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final author = json['Author'] as Map<String, dynamic>? ?? json['author'] as Map<String, dynamic>?;
    if (author == null) return null;
    final profile = author['UserProfile'] as Map<String, dynamic>? ?? author['userProfile'] as Map<String, dynamic>?;
    final nick = profile?['nickname'];
    return nick?.toString();
  }

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    final authorId = _toString(json['authorId'] ?? (json['Author'] is Map ? (json['Author'] as Map)['id'] : null));
    return ItineraryModel(
      id: _toString(json['id']),
      authorId: authorId,
      authorNickname: _authorNicknameFromJson(json),
      title: _toString(json['title']),
      description: _toString(json['description']),
      startDate: _toDateTime(json['startDate']),
      endDate: _toDateTime(json['endDate']),
      imageUrls: _toStringList(json['imageUrls'] as List<dynamic>?),
      mapData: _toMapDataList(json['mapData'] as List<dynamic>?),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'imageUrls': imageUrls,
      'mapData': mapData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ItineraryModel copyWith({
    String? id,
    String? authorId,
    String? authorNickname,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? imageUrls,
    List<Map<String, double>>? mapData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItineraryModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrls: imageUrls ?? this.imageUrls,
      mapData: mapData ?? this.mapData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
