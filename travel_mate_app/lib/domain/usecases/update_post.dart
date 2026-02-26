/// 게시글 수정 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class UpdatePost {
  final PostRepository repository;

  UpdatePost(this.repository);

  Future<void> execute(Post post) async {
    return await repository.updatePost(post);
  }
}