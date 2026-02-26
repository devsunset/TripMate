import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/comment.dart';
import 'package:travel_mate_app/domain/usecases/get_comments.dart';
import 'package:travel_mate_app/domain/usecases/add_comment.dart';
import 'package:travel_mate_app/domain/usecases/delete_comment.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 댓글 부모 타입(게시글 또는 일정).
enum CommentParentType { post, itinerary }

/// 댓글 목록·작성·삭제(본인 댓글만) 섹션. 로그인 사용자만 작성/삭제 가능.
class CommentSectionWidget extends StatefulWidget {
  final CommentParentType parentType;
  final String parentId;

  const CommentSectionWidget({
    super.key,
    required this.parentType,
    required this.parentId,
  });

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadComments();
  }

  Future<void> _loadCurrentUserId() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = await authService.getCurrentBackendUserId();
    if (mounted) setState(() => _currentUserId = userId);
  }

  Future<void> _loadComments() async {
    if (widget.parentId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getComments = Provider.of<GetComments>(context, listen: false);
      final list = widget.parentType == CommentParentType.post
          ? await getComments.forPost(widget.parentId)
          : await getComments.forItinerary(widget.parentId);

      if (mounted) {
        setState(() {
          _comments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '댓글을 불러오지 못했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력하세요.')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 쓰려면 로그인하세요.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final addComment = Provider.of<AddComment>(context, listen: false);
      if (widget.parentType == CommentParentType.post) {
        await addComment.execute(postId: widget.parentId, content: content);
      } else {
        await addComment.execute(itineraryId: widget.parentId, content: content);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 등록되었습니다.')),
        );
        _commentController.clear();
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 등록 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    if (_currentUserId == null) return;
    if (comment.authorId != _currentUserId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final deleteComment = Provider.of<DeleteComment>(context, listen: false);
      await deleteComment.execute(comment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다.')),
        );
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMedium),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '아직 댓글이 없습니다. 첫 댓글을 남겨 보세요.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return _CommentItem(
                comment: comment,
                currentUserId: _currentUserId,
                onDelete: _deleteComment,
                onReplied: _loadComments,
              );
            },
          ),
        const SizedBox(height: AppConstants.spacingLarge),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: _currentUserId == null ? '로그인 후 댓글을 입력하세요.' : '댓글을 입력하세요...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingSmall),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _currentUserId == null ? null : _addComment,
                  ),
          ),
          maxLines: null,
          enabled: _currentUserId != null,
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final String? currentUserId;
  final void Function(Comment) onDelete;
  final VoidCallback onReplied;

  const _CommentItem({
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
    required this.onReplied,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = currentUserId != null && comment.authorId == currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                child: Icon(Icons.person, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorNickname ?? (comment.authorId.length > 6 ? '${comment.authorId.substring(0, 6)}…' : comment.authorId),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (canDelete) ...[
                          const Spacer(),
                          TextButton(
                            onPressed: () => onDelete(comment),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '삭제',
                              style: TextStyle(fontSize: 12, color: AppColors.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 8),
                child: _CommentItem(
                  comment: reply,
                  currentUserId: currentUserId,
                  onDelete: onDelete,
                  onReplied: onReplied,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${d.month}/${d.day}';
  }
}
