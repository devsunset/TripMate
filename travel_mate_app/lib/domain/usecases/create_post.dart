/// 게시글 생성 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class CreatePost {
  final PostRepository repository;

  CreatePost(this.repository);

  Future<void> execute(Post post) async {
    return await repository.createPost(post);
  }
}