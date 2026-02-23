import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill_delta;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/usecases/get_post.dart';
import 'package:travel_mate_app/domain/usecases/delete_post.dart';
import 'package:travel_mate_app/domain/usecases/create_chat_room.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';

/// 게시글 상세 화면. 수정/삭제/신고 버튼.
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Post? _post;
  quill.QuillController? _quillViewController;
  final FocusNode _viewFocusNode = FocusNode();
  final ScrollController _viewScrollController = ScrollController();

  static bool _isQuillContent(String content) {
    return content.trim().startsWith('[');
  }

  static quill.Document _documentFromContent(String content) {
    if (content.trim().isEmpty) {
      return quill.Document();
    }
    try {
      final s = content.trim();
      if (s.startsWith('[')) {
        final list = jsonDecode(content) as List;
        return quill.Document.fromDelta(quill_delta.Delta.fromJson(list));
      }
    } catch (_) {}
    return quill.Document.fromDelta(quill_delta.Delta()..insert(content));
  }

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  @override
  void dispose() {
    _quillViewController?.dispose();
    _viewFocusNode.dispose();
    _viewScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    if (widget.postId.isEmpty) {
      setState(() {
        _errorMessage = '글을 찾을 수 없습니다.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getPost = Provider.of<GetPost>(context, listen: false);
      final fetchedPost = await getPost.execute(widget.postId);

      quill.QuillController? viewController;
      if (_isQuillContent(fetchedPost.content)) {
        viewController = quill.QuillController(
          document: _documentFromContent(fetchedPost.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      if (mounted) {
        setState(() {
          _post = fetchedPost;
          _quillViewController?.dispose();
          _quillViewController = viewController;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '글을 불러오지 못했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('글 삭제'),
        content: const Text(
          '이 글을 삭제하시겠습니까? 삭제된 글은 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final deletePost = Provider.of<DeletePost>(context, listen: false);
        await deletePost.execute(widget.postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('글이 삭제되었습니다.')),
          );
          context.go('/community'); // Go back to community list
        }
      } catch (e) {
        setState(() {
          _errorMessage = '글 삭제 실패: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.email ?? currentUser?.uid ?? '';
    final isAuthor = _post != null && _post!.authorId == currentUserId;

    return Scaffold(
      appBar: AppAppBar(
        title: _post?.title ?? '게시글',
        actions: [
          if (isAuthor) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.go('/community/post/${widget.postId}/edit'); // Navigate to edit post screen
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
            ),
          ],
          if (!isAuthor && _post != null) ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: '작성자에게 채팅하기',
              onPressed: () async {
                try {
                  final createChatRoom = Provider.of<CreateChatRoom>(context, listen: false);
                  await createChatRoom.execute(_post!.authorId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('채팅 요청이 완료되었습니다. 채팅 목록에서 대화를 이어가세요.')),
                    );
                    context.go('/chat');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('채팅 요청에 실패했습니다. $e')),
                    );
                  }
                }
              },
            ),
            ReportButtonWidget(entityType: ReportEntityType.post, entityId: widget.postId),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _post == null
                  ? Center(
                      child: Text(
                        '글을 찾을 수 없습니다.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post!.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingSmall),
                          Text(
                            'Category: ${_post!.category} - Posted by ${_post!.authorId}', // TODO: Display author's nickname
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          if (_post!.imageUrls.isNotEmpty)
                            SizedBox(
                              height: 200, // Adjust height as needed
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _post!.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                      child: CachedNetworkImage(
                                        imageUrl: _post!.imageUrls[index],
                                        width: 250, // Adjust width as needed
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          if (_quillViewController != null)
                            Container(
                              width: double.infinity,
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: quill.QuillEditor.basic(
                                configurations: quill.QuillEditorConfigurations(
                                  controller: _quillViewController!,
                                  readOnly: true,
                                  padding: EdgeInsets.zero,
                                ),
                                focusNode: _viewFocusNode,
                                scrollController: _viewScrollController,
                              ),
                            )
                          else
                            Text(
                              _post!.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          const SizedBox(height: AppConstants.spacingLarge),
                          Text(
                            'Comments (Placeholder)',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text('아직 댓글이 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
    );
  }
}
