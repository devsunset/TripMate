import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart'; // Add this import

/// 로그인 후 홈 화면. 히어로 + 기능 카드 + 탐색 버튼 (Travel-Companion-Finder 스타일).
/// 뷰포트 높이에 맞춰 반응형으로 간격·폰트·그리드 크기 조정.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final h = MediaQuery.sizeOf(context).height;
    final isCompact = h < 680;
    final isMedium = h >= 680 && h < 820;

    // 반응형 값: 작은 화면일수록 여백·폰트·버튼 높이 축소
    final headerPaddingV = isCompact ? 6.0 : (isMedium ? 10.0 : AppConstants.paddingMedium);
    final heroTop = isCompact ? 8.0 : (isMedium ? 14.0 : 24.0);
    final badgePaddingH = isCompact ? 10.0 : 14.0;
    final badgePaddingV = isCompact ? 5.0 : 8.0;
    final badgeFontSize = isCompact ? 11.0 : 12.0;
    final heroTitleSize = isCompact ? 26.0 : (isMedium ? 30.0 : 36.0);
    final heroSubtitleSize = isCompact ? 12.0 : (isMedium ? 13.0 : 15.0);
    final heroAfterTitle = isCompact ? 6.0 : 12.0;
    final heroBottom = isCompact ? 12.0 : (isMedium ? 18.0 : 24.0);
    final gridSpacing = isCompact ? 8.0 : 10.0;
    // 카드에 큰 아이콘 넣을 수 있도록 비율 (세로 여유)
    final gridAspectRatio = isCompact ? 1.55 : (isMedium ? 1.45 : 1.35);
    final bottomPadding = isCompact ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.background,
              AppColors.background.withOpacity(0.98),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: headerPaddingV),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompact ? 8 : 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.explore, color: Colors.white, size: isCompact ? 20 : 24),
                          ),
                          SizedBox(width: isCompact ? 8 : 10),
                          Text('TripMate', style: GoogleFonts.outfit(fontSize: isCompact ? 18 : 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.person_outline, color: AppColors.textPrimary, size: isCompact ? 22 : 24),
                            onPressed: () {
                              if (currentUserUid != null) context.go('/users/$currentUserUid');
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: isCompact ? 22 : 24),
                            onPressed: () => context.go('/settings/account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: heroTop),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Text('Explore the world together', style: GoogleFonts.plusJakartaSans(fontSize: badgeFontSize, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                      ),
                      SizedBox(height: isCompact ? 8 : 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text('Find Your\nTravel Squad', style: GoogleFonts.outfit(fontSize: heroTitleSize, fontWeight: FontWeight.bold, height: 1.15, color: Colors.white)),
                      ),
                      SizedBox(height: heroAfterTitle),
                      Text('같은 취향의 여행자와 만나고, 일정을 공유하고, 추억을 나눠보세요.', style: GoogleFonts.plusJakartaSans(fontSize: heroSubtitleSize, color: AppColors.textSecondary, height: 1.4)),
                      SizedBox(height: heroBottom),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: gridSpacing,
                    crossAxisSpacing: gridSpacing,
                    childAspectRatio: gridAspectRatio,
                  ),
                  delegate: SliverChildListDelegate([
                    _NavCard(icon: Icons.person_search_rounded, label: '동행 찾기', color: AppColors.secondary, onTap: () => context.go('/matching/search'), compact: isCompact),
                    _NavCard(icon: Icons.chat_bubble_outline_rounded, label: '채팅', color: AppColors.primary, onTap: () => context.go('/chat'), compact: isCompact),
                    _NavCard(icon: Icons.article_outlined, label: '커뮤니티', color: AppColors.accent, onTap: () => context.go('/community'), compact: isCompact),
                    _NavCard(icon: Icons.calendar_month_rounded, label: '일정', color: AppColors.secondary, onTap: () => context.go('/itinerary'), compact: isCompact),
                  ]),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _NavCard({required this.icon, required this.label, required this.color, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 10.0 : 14.0;
    final iconWrap = compact ? 14.0 : 18.0;
    final iconSize = compact ? 30.0 : 38.0;
    final gap = compact ? 6.0 : 10.0;
    final fontSize = compact ? 12.0 : 14.0;
    // 다크 배경과 구분: 글래스 느낌 + 네온 테두리/글로우
    const cardSurfaceLight = Color(0xFF16162A);
    const cardSurfaceLighter = Color(0xFF1C1C34);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding + 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardSurfaceLight,
                cardSurfaceLighter,
                color.withOpacity(0.06),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconWrap),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.35),
                      color.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: gap),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
