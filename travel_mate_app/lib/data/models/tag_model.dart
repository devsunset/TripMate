/// 태그 DTO( id, tagName, type ). 동행 검색 필터 등에 사용.
library;
import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final int id;
  final String tagName;
  final String tagType; // e.g., 'travel_style', 'interest_activity'

  const Tag({
    required this.id,
    required this.tagName,
    required this.tagType,
  });

  /// 백엔드가 id를 int 또는 string으로 보낼 수 있음.
  factory Tag.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
    final tagName = json['tag_name'] == null ? '' : (json['tag_name'] is int ? (json['tag_name'] as int).toString() : json['tag_name'] as String);
    final tagType = json['tag_type'] == null ? '' : (json['tag_type'] is int ? (json['tag_type'] as int).toString() : json['tag_type'] as String);
    return Tag(id: id, tagName: tagName, tagType: tagType);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_name': tagName,
      'tag_type': tagType,
    };
  }

  @override
  List<Object?> get props => [id, tagName, tagType];
}