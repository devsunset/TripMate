/// 태그 타입별 조회 유스케이스.
library;
import 'package:travel_mate_app/data/models/tag_model.dart';
import 'package:travel_mate_app/domain/repositories/tag_repository.dart';

class GetTags {
  final TagRepository repository;

  GetTags(this.repository);

  Future<List<Tag>> call(String tagType) {
    return repository.getTagsByType(tagType);
  }
}