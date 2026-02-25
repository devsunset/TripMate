/// 댓글 삭제. 본인 댓글만 삭제 가능(백엔드 403).
import 'package:travel_mate_app/domain/repositories/comment_repository.dart';

class DeleteComment {
  final CommentRepository repository;

  DeleteComment(this.repository);

  Future<void> execute(int commentId) => repository.deleteComment(commentId);
}
