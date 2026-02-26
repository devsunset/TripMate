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
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmpty = false;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isEmpty = false;
    });

    try {
      final getPosts = Provider.of<GetPosts>(context, listen: false);
      final fetchedPosts = await getPosts.execute();

      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
        _errorMessage = null;
        _isEmpty = _posts.isEmpty;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '글 목록을 불러오지 못했습니다.';
        _isLoading = false;
        _isEmpty = false;
      });
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
                    padding: EdgeInsets.only(
                      left: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      right: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      bottom: MediaQuery.paddingOf(context).bottom + 8,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
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
