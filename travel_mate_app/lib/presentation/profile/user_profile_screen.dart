import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/domain/usecases/get_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/create_chat_room.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 특정 사용자 프로필 보기 화면. userId로 조회.
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfile? _userProfile;
  String? _currentUserId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _errorMessage = '프로필을 찾을 수 없습니다.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = await authService.getCurrentBackendUserId();
      final getUserProfile = Provider.of<GetUserProfile>(context, listen: false);
      final profile = await getUserProfile.execute(widget.userId);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '프로필을 불러오지 못했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId ?? '';
    final isMyProfile = currentUserId == widget.userId;

    // 소개·여행 스타일·관심사만 표시 (선호 지역은 입력 UI 없어 제외)
    const sectionColors = [
      Color(0xFF0EA5E9), // Sky - 소개
      Color(0xFF14B8A6), // Teal - 여행 스타일
      Color(0xFFF59E0B), // Amber - 관심사
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E32),
      appBar: AppAppBar(
        title: isMyProfile ? '내 프로필' : (_userProfile?.nickname ?? '프로필'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/profile/edit'),
            ),
          if (!isMyProfile && _userProfile != null) ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () async {
                try {
                  final createChatRoom = Provider.of<CreateChatRoom>(context, listen: false);
                  await createChatRoom.execute(widget.userId);
                  if (context.mounted) context.go('/chat');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('채팅 요청에 실패했습니다. $e')),
                    );
                  }
                }
              },
            ),
            ReportButtonWidget(entityType: ReportEntityType.user, entityId: widget.userId),
          ],
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1E1E32)),
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
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildAvatar(),
                          const SizedBox(height: 20),
                          Text(
                            _userProfile?.nickname ?? '-',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 1)),
                                Shadow(color: Colors.black38, blurRadius: 4, offset: const Offset(0, 0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?.gender != null && _userProfile!.gender!.isNotEmpty &&
                                    _userProfile?.ageRange != null && _userProfile!.ageRange!.isNotEmpty
                                ? '${_userProfile!.gender} · ${_userProfile!.ageRange}'
                                : '추가 정보 없음',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4, offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildSection(title: '소개', content: _userProfile?.bio ?? '소개가 없습니다.', icon: Icons.info_outline_rounded, color: sectionColors[0]),
                          const SizedBox(height: 14),
                          _buildSection(title: '여행 스타일', content: _userProfile?.travelStyles.join(', ') ?? '선택된 여행 스타일이 없습니다.', icon: Icons.explore_rounded, color: sectionColors[1]),
                          const SizedBox(height: 14),
                          _buildSection(title: '관심사', content: _userProfile?.interests.join(', ') ?? '선택된 관심사가 없습니다.', icon: Icons.favorite_outline_rounded, color: sectionColors[2]),
                          if (isMyProfile) ...[
                            const SizedBox(height: 28),
                            _buildSettingsRow(context),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final hasImage = _userProfile?.profileImageUrl != null && _userProfile!.profileImageUrl!.isNotEmpty;
    const color = Color(0xFF0EA5E9);
    final cardBase = Color.lerp(Colors.white, color, 0.15)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 16, spreadRadius: 0),
        ],
        color: cardBase,
      ),
      child: CircleAvatar(
        radius: 56,
        backgroundColor: AppColors.lightGrey,
        backgroundImage: hasImage ? NetworkImage(_userProfile!.profileImageUrl!) : null,
        child: hasImage ? null : Icon(Icons.person, size: 64, color: AppColors.grey),
      ),
    );
  }

  /// 카드 배경이 밝은 색이므로 제목·본문은 진한 색으로 표시해 가독성 확보.
  static const Color _cardTextTitle = Color(0xFF1A1A2E);
  static const Color _cardTextBody = Color(0xFF374151);

  Widget _buildSection({required String title, required String content, required IconData icon, required Color color}) {
    final cardBase = Color.lerp(Colors.white, color, 0.12)!;
    final cardHighlight = Color.lerp(Colors.white, color, 0.22)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBase,
            cardHighlight,
            color.withOpacity(0.12),
          ],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: _cardTextTitle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.45, color: _cardTextBody),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: Icon(Icons.logout_rounded, size: 20, color: Colors.white.withOpacity(0.9)),
            label: Text(
              '로그아웃',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white.withOpacity(0.9)),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
