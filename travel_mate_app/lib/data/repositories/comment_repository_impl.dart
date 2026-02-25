/// 댓글 레포지토리 구현.
import 'package:travel_mate_app/domain/entities/comment.dart';
import 'package:travel_mate_app/domain/repositories/comment_repository.dart';
import 'package:travel_mate_app/data/datasources/comment_remote_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource remoteDataSource;

  CommentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Comment>> getCommentsForPost(String postId) =>
      remoteDataSource.getCommentsForPost(postId);

  @override
  Future<List<Comment>> getCommentsForItinerary(String itineraryId) =>
      remoteDataSource.getCommentsForItinerary(itineraryId);

  @override
  Future<Comment> addComment({
    String? postId,
    String? itineraryId,
    int? parentCommentId,
    required String content,
  }) =>
      remoteDataSource.addComment(
        postId: postId,
        itineraryId: itineraryId,
        parentCommentId: parentCommentId,
        content: content,
      );

  @override
  Future<void> deleteComment(int commentId) =>
      remoteDataSource.deleteComment(commentId);
}
