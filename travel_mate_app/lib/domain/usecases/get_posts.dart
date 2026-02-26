/// 게시글 목록 조회 유스케이스.
library;
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class GetPosts {
  final PostRepository repository;

  GetPosts(this.repository);

  Future<List<Post>> execute() async {
    return await repository.getPosts();
  }
}