/// 게시글 삭제 유스케이스.
library;
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class DeletePost {
  final PostRepository repository;

  DeletePost(this.repository);

  Future<void> execute(String postId) async {
    return await repository.deletePost(postId);
  }
}