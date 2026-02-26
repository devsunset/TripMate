/// 게시글 CRUD 추상 레포지토리
library;
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/entities/post.dart';

abstract class PostRepository {
  /// 페이징: limit, offset 기본 20, 0. total 포함 반환.
  Future<PaginatedResult<Post>> getPosts({int limit = 20, int offset = 0});
  Future<Post> getPost(String postId);
  Future<void> createPost(Post post);
  Future<void> updatePost(Post post);
  Future<void> deletePost(String postId);
  Future<String> uploadPostImage(String postId, String imagePath);
}