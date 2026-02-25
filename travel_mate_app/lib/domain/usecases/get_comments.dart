/// 게시글 또는 일정의 댓글 목록 조회.
import 'package:travel_mate_app/domain/entities/comment.dart';
import 'package:travel_mate_app/domain/repositories/comment_repository.dart';

class GetComments {
  final CommentRepository repository;

  GetComments(this.repository);

  Future<List<Comment>> forPost(String postId) => repository.getCommentsForPost(postId);
  Future<List<Comment>> forItinerary(String itineraryId) => repository.getCommentsForItinerary(itineraryId);
}
