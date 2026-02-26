/// 태그 조회 추상 레포지토리
library;
import 'package:travel_mate_app/data/models/tag_model.dart';

abstract class TagRepository {
  Future<List<Tag>> getTagsByType(String tagType);
  Future<List<Tag>> getAllTags();
  // Future<void> createTag(Tag tag); // Tags are probably pre-defined by admin
}