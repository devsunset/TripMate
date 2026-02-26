import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 로그인 화면. Google 로그인만 지원(이메일 미수집·미저장).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithGoogle();

      if (user != null) {
        await authService.getCurrentBackendUserId();
        if (mounted) context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Google 로그인이 취소되었거나 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google 로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.isCompact(context);
    final padding = Responsive.value(context, compact: AppConstants.paddingMedium, medium: AppConstants.paddingLarge, expanded: AppConstants.paddingLarge);
    final spacing = Responsive.value(context, compact: AppConstants.spacingMedium, medium: AppConstants.spacingLarge, expanded: AppConstants.spacingLarge);
    final logoSize = Responsive.value(context, compact: 36.0, medium: 44.0, expanded: 44.0);
    final titleFontSize = Responsive.value(context, compact: 18.0, medium: 22.0, expanded: 22.0);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.85),
        scrolledUnderElevation: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
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
            Text('TravelMate', style: GoogleFonts.outfit(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Column(
              children: [
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing),
                // 가운데 영역: 앱 성격에 맞는 여행 이미지 + 캐치프레이즈
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.landscape_rounded, size: 64, color: AppColors.primary),
                          ),
                        ),
                      ),
                      // 하단 그라데이션 + 문구
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(Responsive.value(context, compact: 14.0, medium: 18.0, expanded: 20.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                            ),
                          ),
                          child: Text(
                            '같은 취향의 여행자와 만나\n일정을 공유하고 추억을 나눠보세요.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: Responsive.value(context, compact: 13.0, medium: 14.0, expanded: 15.0),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: Icon(Icons.g_mobiledata, size: isCompact ? 20 : 24, color: AppColors.textPrimary),
                          label: Text(
                            'Google로 로그인',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isCompact ? AppConstants.paddingSmall : AppConstants.paddingMedium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            ),
                            side: BorderSide(color: AppColors.grey),
                          ),
                        ),
                      ),
                SizedBox(height: spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '계정이 없으신가요?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(
                        'Google로 시작하기',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
