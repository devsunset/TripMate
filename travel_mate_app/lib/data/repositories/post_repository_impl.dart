/// 게시글 레포지토리 구현. 원격 데이터소스 위임.
library;
import 'dart:io' if (dart.library.html) 'package:travel_mate_app/core/io_stub/file_stub.dart';

import 'package:travel_mate_app/data/datasources/post_remote_datasource.dart';
import 'package:travel_mate_app/data/models/post_model.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaginatedResult<Post>> getPosts({int limit = 20, int offset = 0}) async {
    final result = await remoteDataSource.getPosts(limit: limit, offset: offset);
    return PaginatedResult<Post>(items: result.items, total: result.total);
  }

  @override
  Future<Post> getPost(String postId) async {
    return await remoteDataSource.getPost(postId);
  }

  @override
  Future<void> createPost(Post post) async {
    if (post is PostModel) {
      await remoteDataSource.createPost(post);
    } else {
      await remoteDataSource.createPost(PostModel(
        id: post.id,
        authorId: post.authorId,
        title: post.title,
        content: post.content,
        category: post.category,
        imageUrls: post.imageUrls,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      ));
    }
  }

  @override
  Future<void> updatePost(Post post) async {
    if (post is PostModel) {
      await remoteDataSource.updatePost(post);
    } else {
      await remoteDataSource.updatePost(PostModel(
        id: post.id,
        authorId: post.authorId,
        title: post.title,
        content: post.content,
        category: post.category,
        imageUrls: post.imageUrls,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      ));
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    await remoteDataSource.deletePost(postId);
  }

  @override
  Future<String> uploadPostImage(String postId, String imagePath) async {
    // 게시글 이미지는 백엔드 업로드 시 사용자 ID로 경로가 구성됨
    // Assuming the authorId is the current user's Firebase UID
    final currentUserId = 'currentUserId'; // TODO: Get actual current user ID from Firebase Auth
    return await remoteDataSource.uploadPostImage(currentUserId, File(imagePath));
  }
}
