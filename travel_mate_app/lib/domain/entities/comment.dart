/// 댓글 엔티티 (게시글/일정 댓글·대댓글).
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final int id;
  final String authorId;
  /// 표시용 작성자 닉네임 (API에서 Author.UserProfile.nickname 등으로 내려줌).
  final String? authorNickname;
  final int? postId;
  final int? itineraryId;
  final int? parentCommentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// 대댓글 목록 (최상위 댓글만 사용).
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.authorId,
    this.authorNickname,
    this.postId,
    this.itineraryId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  @override
  List<Object?> get props => [id, authorId, content, createdAt];
}
