/// 게시글 이미지 업로드 유스케이스. 업로드된 이미지 URL 반환.
library;
import 'package:travel_mate_app/domain/repositories/post_repository.dart';

class UploadPostImage {
  final PostRepository repository;

  UploadPostImage(this.repository);

  Future<String> execute(String postId, String imagePath) async {
    return await repository.uploadPostImage(postId, imagePath);
  }
}