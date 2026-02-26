/// 게시글 목록 조회 유스케이스. 페이징 지원.
library;
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class GetPosts {
  final PostRepository repository;

  GetPosts(this.repository);

  Future<PaginatedResult<Post>> execute({int limit = 20, int offset = 0}) async {
    return await repository.getPosts(limit: limit, offset: offset);
  }
}