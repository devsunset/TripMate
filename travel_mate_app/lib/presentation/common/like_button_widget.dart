import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/theme.dart';

/// 콘텐츠 타입(게시글 또는 일정).
enum ContentType { post, itinerary }

/// 좋아요 버튼 위젯. 토글 시 백엔드 연동, 좋아요 수 표시.
class LikeButtonWidget extends StatefulWidget {
  final ContentType contentType;
  final String contentId;
  final int initialLikeCount;
  final bool initialIsLiked;

  const LikeButtonWidget({
    super.key,
    required this.contentType,
    required this.contentId,
    this.initialLikeCount = 0,
    this.initialIsLiked = false,
  });

  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  late int _likeCount;
  late bool _isLiked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _isLiked = widget.initialIsLiked;
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요하려면 로그인하세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optimistic UI update
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });

      // TODO: Call toggleLike usecase
      // final toggleLike = Provider.of<ToggleLike>(context, listen: false);
      // await toggleLike.execute(
      //   contentType: widget.contentType,
      //   contentId: widget.contentId,
      //   isLiked: _isLiked,
      // );

      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network
    } catch (e) {
      // Revert UI on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 변경 실패: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleLike,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : AppColors.grey,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            '$_likeCount',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
