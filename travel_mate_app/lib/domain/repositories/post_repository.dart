/// 게시글 CRUD 추상 레포지토리
library;
import 'package:travel_mate_app/domain/entities/post.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts();
  Future<Post> getPost(String postId);
  Future<void> createPost(Post post);
  Future<void> updatePost(Post post);
  Future<void> deletePost(String postId);
  Future<String> uploadPostImage(String postId, String imagePath);
}