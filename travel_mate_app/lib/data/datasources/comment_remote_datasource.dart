/// 댓글 API 호출.
library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/comment.dart';

class CommentRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  CommentRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  Future<String> _getIdToken() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) throw Exception('로그인이 필요합니다.');
    return token;
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    final token = await _getIdToken();
    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/api/comments',
      queryParameters: {'postId': postId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('댓글 목록 조회 실패');
    final list = response.data['comments'] as List? ?? [];
    return list.map((e) => _commentFromJson(e)).toList();
  }

  Future<List<Comment>> getCommentsForItinerary(String itineraryId) async {
    final token = await _getIdToken();
    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/api/comments',
      queryParameters: {'itineraryId': itineraryId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('댓글 목록 조회 실패');
    final list = response.data['comments'] as List? ?? [];
    return list.map((e) => _commentFromJson(e)).toList();
  }

  Future<Comment> addComment({
    String? postId,
    String? itineraryId,
    int? parentCommentId,
    required String content,
  }) async {
    final token = await _getIdToken();
    final body = <String, dynamic>{
      'content': content,
      'parentCommentId': ?parentCommentId,
    };
    if (postId != null) body['postId'] = int.tryParse(postId) ?? postId;
    if (itineraryId != null) body['itineraryId'] = int.tryParse(itineraryId) ?? itineraryId;

    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/api/comments',
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) throw Exception('댓글 등록 실패');
    final data = response.data['comment'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>;
    return _commentFromJson(data);
  }

  Future<void> deleteComment(int commentId) async {
    final token = await _getIdToken();
    final response = await _dio.delete(
      '${AppConstants.apiBaseUrl}/api/comments/$commentId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 204 && response.statusCode != 200) throw Exception('댓글 삭제 실패');
  }

  static String? _authorNicknameFromMap(Map<String, dynamic> map) {
    final author = map['Author'] as Map<String, dynamic>? ?? map['author'] as Map<String, dynamic>?;
    if (author == null) return null;
    final profile = author['UserProfile'] as Map<String, dynamic>? ?? author['userProfile'] as Map<String, dynamic>?;
    final nick = profile?['nickname'];
    return nick?.toString();
  }

  static Comment _commentFromJson(dynamic e) {
    final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
    final replies = (map['Replies'] as List? ?? map['replies'] as List? ?? [])
        .map((r) => _commentFromJson(r))
        .toList();
    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'].toString()) ?? createdAt
        : createdAt;
    final authorId = (map['Author'] != null ? (map['Author'] as Map)['id'] : null)?.toString() ?? map['authorId']?.toString() ?? '';
    return Comment(
      id: int.parse(map['id'].toString()),
      authorId: authorId,
      authorNickname: _authorNicknameFromMap(map),
      postId: map['postId'] != null ? int.tryParse(map['postId'].toString()) : null,
      itineraryId: map['itineraryId'] != null ? int.tryParse(map['itineraryId'].toString()) : null,
      parentCommentId: map['parentCommentId'] != null ? int.tryParse(map['parentCommentId'].toString()) : null,
      content: map['content']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      replies: replies,
    );
  }
}
