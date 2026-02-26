import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
/// 로그인 후 홈 화면. 히어로 + 기능 카드 + 탐색 버튼 (Travel-Companion-Finder 스타일).
/// 뷰포트 높이에 맞춰 반응형으로 간격·폰트·그리드 크기 조정. 사용자 식별은 백엔드 id만 사용.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenBody();
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyBackendSession());
  }

  /// 메인 화면 진입 시 백엔드 세션 유효성 재확인. 401 등이면 로그아웃 처리해 로그인 화면으로 보냄.
  Future<void> _verifyBackendSession() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    final userId = await auth.getCurrentBackendUserId();
    if (userId == null && mounted) {
      await auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = h < 680 || w < Responsive.breakpointMedium;
    final isMedium = !isCompact && (h < 820 || w < Responsive.breakpointExpanded);

    // 반응형 값: 작은 화면일수록 여백·폰트·버튼 높이 축소
    final headerPaddingH = Responsive.value(context, compact: AppConstants.paddingMedium, medium: AppConstants.paddingLarge, expanded: AppConstants.paddingLarge);
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
    final bottomPadding = isCompact ? 24.0 : 32.0;

    // 카드별 색상 + 주제에 맞는 배경 이미지 (동행, 채팅, 커뮤니티, 일정)
    const cardColors = [
      Color(0xFF14B8A6), // Teal - 동행 찾기
      Color(0xFF0EA5E9), // Sky - 채팅
      Color(0xFFF59E0B), // Amber - 커뮤니티
      Color(0xFF10B981), // Emerald - 일정
    ];
    final cardBgImages = AppConstants.sectionBackgroundImages;
    final navCards = [
      (Icons.person_search_rounded, '동행 찾기', cardColors[0], cardBgImages[0], () => context.go('/matching/search', extra: cardBgImages[0])),
      (Icons.chat_bubble_outline_rounded, '채팅', cardColors[1], cardBgImages[1], () => context.go('/chat', extra: cardBgImages[1])),
      (Icons.article_outlined, '커뮤니티', cardColors[2], cardBgImages[2], () => context.go('/community', extra: cardBgImages[2])),
      (Icons.calendar_month_rounded, '일정', cardColors[3], cardBgImages[3], () => context.go('/itinerary', extra: cardBgImages[3])),
    ];

    // 데스크톱: 콘텐츠 최대 너비 제한(중앙 정렬). 모바일: 전체 너비 사용.
    final maxContentWidth = w >= Responsive.breakpointMedium ? 560.0 : w;
    final padH = headerPaddingH;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 (비행기/여행) — 우측 상단에 위치, 선명하게 보이도록
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800',
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                ),
              ),
            ),
          ),
          // 가벼운 오버레이로 배경 사진이 선명하게 보이도록
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.35),
                    AppColors.background.withOpacity(0.55),
                    AppColors.background.withOpacity(0.78),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: h - MediaQuery.paddingOf(context).vertical,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: padH, vertical: headerPaddingV),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: isCompact ? 40 : 44,
                                    height: isCompact ? 40 : 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'images/app_logo.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isCompact ? 8 : 10),
                                  Text(
                                    'TravelMate',
                                    style: GoogleFonts.outfit(
                                      fontSize: isCompact ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 1)),
                                        Shadow(color: Colors.black38, blurRadius: 4, offset: const Offset(0, 0)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.person_outline, color: Colors.white, size: isCompact ? 22 : 24),
                                    onPressed: () => context.go('/profile'),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.settings_outlined, color: Colors.white, size: isCompact ? 22 : 24),
                                    onPressed: () => context.go('/settings/account'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: padH),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: heroTop),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Explore the world together',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: badgeFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(color: Colors.black45, blurRadius: 4, offset: const Offset(0, 1)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompact ? 8 : 16),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'Find Your\nTravel Squad',
                                  style: GoogleFonts.outfit(
                                    fontSize: heroTitleSize,
                                    fontWeight: FontWeight.bold,
                                    height: 1.15,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 10, offset: const Offset(0, 2)),
                                      Shadow(color: Colors.black38, blurRadius: 4, offset: const Offset(0, 0)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: heroAfterTitle),
                              Text(
                                '같은 취향의 여행자와 만나고, 일정을 공유하고, 추억을 나눠보세요.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: heroSubtitleSize,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                  shadows: [
                                    Shadow(color: Colors.black54, blurRadius: 6, offset: const Offset(0, 1)),
                                    Shadow(color: Colors.black38, blurRadius: 2, offset: const Offset(0, 0)),
                                  ],
                                ),
                              ),
                              SizedBox(height: heroBottom),
                            ],
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final viewportHeight = h - MediaQuery.paddingOf(context).top - MediaQuery.paddingOf(context).bottom;
                            final estimatedHeaderHero = isCompact ? 200.0 : 260.0;
                            final gridHeight = (viewportHeight - estimatedHeaderHero - bottomPadding).clamp(200.0, 420.0);
                            final contentWidth = (maxContentWidth - 2 * padH - gridSpacing).clamp(200.0, double.infinity);
                            final cellWidth = (contentWidth) / 2;
                            final rowHeight = (gridHeight - gridSpacing) / 2;
                            final aspectRatio = (cellWidth / rowHeight.clamp(40.0, double.infinity)).clamp(0.6, 1.4);
                            return Padding(
                              padding: EdgeInsets.only(left: padH, right: padH, bottom: bottomPadding),
                              child: SizedBox(
                                height: gridHeight,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: gridSpacing,
                                    crossAxisSpacing: gridSpacing,
                                    childAspectRatio: aspectRatio,
                                  ),
                                  itemCount: 4,
                                  itemBuilder: (context, index) {
                                    final item = navCards[index];
                                    return _NavCard(icon: item.$1, label: item.$2, color: item.$3, backgroundImageUrl: item.$4, onTap: item.$5, compact: isCompact);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String backgroundImageUrl;
  final VoidCallback onTap;
  final bool compact;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundImageUrl,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 10.0 : 14.0;
    final iconWrap = compact ? 14.0 : 18.0;
    final iconSize = compact ? 30.0 : 38.0;
    final gap = compact ? 6.0 : 10.0;
    final fontSize = compact ? 12.0 : 14.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 카드 주제별 배경 이미지
                Positioned.fill(
                  child: Image.network(
                    backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: color.withOpacity(0.25),
                    ),
                  ),
                ),
                // 어두운 오버레이로 글자·아이콘 가독성 확보
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                // 콘텐츠 (흰색 글자·아이콘으로 선명하게)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding + 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconWrap),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                      SizedBox(height: gap),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54, offset: const Offset(0, 1)),
                            Shadow(blurRadius: 8, color: Colors.black45, offset: const Offset(0, 2)),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
