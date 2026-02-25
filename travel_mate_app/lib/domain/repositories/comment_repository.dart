/// 댓글 조회·작성·삭제 추상 레포지토리.
import 'package:travel_mate_app/domain/entities/comment.dart';

abstract class CommentRepository {
  /// 게시글 또는 일정의 댓글 목록 (최상위 + 대댓글).
  Future<List<Comment>> getCommentsForPost(String postId);
  Future<List<Comment>> getCommentsForItinerary(String itineraryId);

  /// 댓글 작성. postId 또는 itineraryId 중 하나 필수.
  Future<Comment> addComment({
    String? postId,
    String? itineraryId,
    int? parentCommentId,
    required String content,
  });

  /// 댓글 삭제. 본인 댓글만 삭제 가능(백엔드에서 403 반환).
  Future<void> deleteComment(int commentId);
}
