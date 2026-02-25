/// 댓글 작성.
import 'package:travel_mate_app/domain/entities/comment.dart';
import 'package:travel_mate_app/domain/repositories/comment_repository.dart';

class AddComment {
  final CommentRepository repository;

  AddComment(this.repository);

  Future<Comment> execute({
    String? postId,
    String? itineraryId,
    int? parentCommentId,
    required String content,
  }) =>
      repository.addComment(
        postId: postId,
        itineraryId: itineraryId,
        parentCommentId: parentCommentId,
        content: content,
      );
}
