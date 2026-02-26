import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/domain/entities/post.dart';
import 'package:travel_mate_app/domain/usecases/get_posts.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/empty_state_widget.dart';

/// 커뮤니티 게시글 목록 화면. 글쓰기·상세 이동.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isEmpty = false;
  List<Post> _posts = [];
  int _total = 0;

  bool get _hasMore => _posts.length < _total;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isEmpty = false;
      _posts = [];
      _total = 0;
    });

    try {
      final getPosts = Provider.of<GetPosts>(context, listen: false);
      final result = await getPosts.execute(limit: _pageSize, offset: 0);

      if (mounted) {
        setState(() {
          _posts = result.items;
          _total = result.total;
          _isLoading = false;
          _errorMessage = null;
          _isEmpty = _posts.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '글 목록을 불러오지 못했습니다.';
          _isLoading = false;
          _isEmpty = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _posts.isEmpty) return;
    setState(() => _isLoadingMore = true);

    try {
      final getPosts = Provider.of<GetPosts>(context, listen: false);
      final result = await getPosts.execute(limit: _pageSize, offset: _posts.length);

      if (mounted) {
        setState(() {
          _posts = [..._posts, ...result.items];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: '커뮤니티',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/community/post/new'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEmpty
              ? EmptyStateWidget(
                  icon: Icons.article_outlined,
                  title: '아직 글이 없어요',
                  subtitle: '첫 여행 이야기를 공유해 보세요!',
                  actionLabel: '글쓰기',
                  onAction: () => context.go('/community/post/new'),
                )
              : _errorMessage != null
                  ? EmptyStateWidget(
                      icon: Icons.cloud_off_rounded,
                      title: _errorMessage!,
                      isError: true,
                      onRetry: _loadPosts,
                    )
                  : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      right: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      bottom: MediaQuery.paddingOf(context).bottom + 8,
                    ),
                    itemCount: _posts.length + (_hasMore && _isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = _posts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                            vertical: AppConstants.paddingSmall),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          leading: post.imageUrls.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(post.imageUrls.first),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.image_not_supported),
                                ),
                          title: Text(post.title),
                          subtitle: Text('${post.category} · ${post.authorNickname ?? post.authorId}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.go('/community/post/${post.id}'); // Navigate to post detail
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
