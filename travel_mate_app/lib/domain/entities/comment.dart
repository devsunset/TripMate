/// 댓글 엔티티 (게시글/일정 댓글·대댓글).
library;
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final int id;
  final String authorId;
  /// 표시용 작성자 닉네임 (API에서 Author.UserProfile.nickname 등으로 내려줌).
  final String? authorNickname;
  /// 작성자 프로필 이미지 URL. 없으면 성별 아이콘 또는 기본 person 아이콘 표시.
  final String? authorProfileImageUrl;
  /// 작성자 성별(예: 남성, 여성). 이미지 없을 때 아이콘 선택용.
  final String? authorGender;
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
    this.authorProfileImageUrl,
    this.authorGender,
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
