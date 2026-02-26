/// 게시글 단건 조회 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class GetPost {
  final PostRepository repository;

  GetPost(this.repository);

  Future<Post> execute(String postId) async {
    return await repository.getPost(postId);
  }
}