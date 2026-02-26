/// 태그 레포지토리 구현. 백엔드 API 또는 로컬 데이터 위임.
library;
import 'package:travel_mate_app/data/models/tag_model.dart';
import 'package:travel_mate_app/domain/repositories/tag_repository.dart';
import 'package:flutter/foundation.dart';

class TagRepositoryImpl implements TagRepository {
  // Dummy data for simulation
  final List<Tag> _dummyTags = const [
    Tag(id: 1, tagName: 'Adventure', tagType: 'travel_style'),
    Tag(id: 2, tagName: 'Relaxation', tagType: 'travel_style'),
    Tag(id: 3, tagName: 'Culture', tagType: 'travel_style'),
    Tag(id: 4, tagName: 'Foodie', tagType: 'travel_style'),
    Tag(id: 5, tagName: 'Hiking', tagType: 'interest_activity'),
    Tag(id: 6, tagName: 'Scuba Diving', tagType: 'interest_activity'),
    Tag(id: 7, tagName: 'Photography', tagType: 'interest_activity'),
    Tag(id: 8, tagName: 'Museums', tagType: 'interest_activity'),
  ];

  @override
  Future<List<Tag>> getTagsByType(String tagType) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    debugPrint('Fetching dummy tags by type: $tagType');
    return _dummyTags.where((tag) => tag.tagType == tagType).toList();
  }

  @override
  Future<List<Tag>> getAllTags() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    debugPrint('Fetching all dummy tags');
    return _dummyTags;
  }
}