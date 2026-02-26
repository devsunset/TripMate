import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/theme.dart';

/// 콘텐츠 타입(게시글 또는 일정). 북마크/좋아요 등에서 사용.
enum ContentType { post, itinerary }

/// 북마크 버튼 위젯. 토글 시 백엔드 연동.
class BookmarkButtonWidget extends StatefulWidget {
  final ContentType contentType;
  final String contentId;
  final bool initialIsBookmarked;

  const BookmarkButtonWidget({
    super.key,
    required this.contentType,
    required this.contentId,
    this.initialIsBookmarked = false,
  });

  @override
  State<BookmarkButtonWidget> createState() => _BookmarkButtonWidgetState();
}

class _BookmarkButtonWidgetState extends State<BookmarkButtonWidget> {
  late bool _isBookmarked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.initialIsBookmarked;
  }

  Future<void> _toggleBookmark() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크하려면 로그인하세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optimistic UI update
      setState(() {
        _isBookmarked = !_isBookmarked;
      });

      // TODO: Call toggleBookmark usecase
      // final toggleBookmark = Provider.of<ToggleBookmark>(context, listen: false);
      // await toggleBookmark.execute(
      //   contentType: widget.contentType,
      //   contentId: widget.contentId,
      //   isBookmarked: _isBookmarked,
      // );

      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network
    } catch (e) {
      // Revert UI on error
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 변경 실패: ${e.toString()}')),
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
      onTap: _isLoading ? null : _toggleBookmark,
      child: Icon(
        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: _isBookmarked ? AppColors.accent : AppColors.grey,
        size: 24,
      ),
    );
  }
}
