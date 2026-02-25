/// 커뮤니티 게시글 엔티티(제목, 내용, 이미지 URL, 작성자, 카테고리, 생성/수정일).
import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String authorId;
  /// 표시용 작성자 닉네임 (API에서 Author.UserProfile.nickname 등으로 내려줌).
  final String? authorNickname;
  final String title;
  final String content;
  final String category;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.authorId,
    this.authorNickname,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorNickname,
        title,
        content,
        category,
        imageUrls,
        createdAt,
        updatedAt,
      ];
}