import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/core/utils/mask_utils.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/profile_avatar_widget.dart';
import 'package:travel_mate_app/domain/usecases/get_user_profile.dart';

/// 현재 사용자 프로필 상세·편집 진입 화면.
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  String get idDisplay => maskForDisplay(_userProfile?.userId).isEmpty ? '-' : maskForDisplay(_userProfile?.userId);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = await authService.getCurrentBackendUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }
      final getUserProfile = Provider.of<GetUserProfile>(context, listen: false);
      final profile = await getUserProfile.execute(userId);
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '프로필을 불러오지 못했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _userProfile?.profileImageUrl != null && _userProfile!.profileImageUrl!.isNotEmpty;

    const sectionColors = [
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E32),
      appBar: AppAppBar(
        title: '내 프로필',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/profile/edit'),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF1E1E32)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E1E32).withOpacity(0.82),
                    const Color(0xFF1E1E32).withOpacity(0.88),
                    const Color(0xFF1E1E32).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          _isLoading
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfileAvatar(
                            profileImageUrl: _userProfile?.profileImageUrl,
                            gender: _userProfile?.gender,
                            radius: 80,
                            iconSize: 80,
                            backgroundColor: AppColors.lightGrey,
                            iconColor: AppColors.grey,
                          ),
                          const SizedBox(height: AppConstants.spacingLarge),
                          Text(
                            _userProfile?.nickname ?? 'N/A',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            idDisplay,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLarge),
                          _buildProfileDetailCard(context, title: '소개', content: _userProfile?.bio ?? '소개가 없습니다.', color: sectionColors[0]),
                          const SizedBox(height: AppConstants.spacingMedium),
                          _buildProfileDetailCard(context, title: '성별', content: _userProfile?.gender ?? '-', color: sectionColors[1]),
                          const SizedBox(height: AppConstants.spacingMedium),
                          _buildProfileDetailCard(context, title: '연령대', content: _userProfile?.ageRange ?? 'N/A', color: sectionColors[2]),
                          const SizedBox(height: AppConstants.spacingMedium),
                          _buildProfileDetailCard(context, title: '여행 스타일', content: _userProfile?.travelStyles.join(', ') ?? '선택된 여행 스타일이 없습니다.', color: sectionColors[3]),
                          const SizedBox(height: AppConstants.spacingMedium),
                          _buildProfileDetailCard(context, title: '관심사', content: _userProfile?.interests.join(', ') ?? '선택된 관심사가 없습니다.', color: sectionColors[0]),
                          const SizedBox(height: AppConstants.spacingMedium),
                          _buildProfileDetailCard(context, title: '선호 지역', content: _userProfile?.preferredDestinations.join(', ') ?? '선택된 선호 지역이 없습니다.', color: sectionColors[1]),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailCard(BuildContext context, {required String title, required String content, required Color color}) {
    final cardBase = Color.lerp(Colors.white, color, 0.12)!;
    final cardHighlight = Color.lerp(Colors.white, color, 0.22)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBase, cardHighlight, color.withOpacity(0.12)],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}