import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';

/// 회원가입 화면. Google 로그인만 지원(이메일 미수집·미저장).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUpWithGoogle() async {
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
    return Scaffold(
      appBar: const AppAppBar(title: '회원가입'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.value(context, compact: AppConstants.paddingMedium, medium: AppConstants.paddingLarge, expanded: AppConstants.paddingLarge),
            vertical: Responsive.value(context, compact: AppConstants.spacingMedium, medium: AppConstants.spacingLarge, expanded: AppConstants.spacingLarge),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '계정 만들기',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                ),
                SizedBox(height: Responsive.value(context, compact: AppConstants.spacingMedium, medium: AppConstants.spacingLarge, expanded: AppConstants.spacingLarge)),
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
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signUpWithGoogle,
                        icon: Icon(Icons.g_mobiledata, size: Responsive.isCompact(context) ? 20 : 24, color: AppColors.textPrimary),
                        label: Text(
                          'Google로 시작하기',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: Responsive.isCompact(context) ? AppConstants.paddingSmall : AppConstants.paddingMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          side: BorderSide(color: AppColors.grey),
                        ),
                      ),
                    ),
                SizedBox(height: Responsive.value(context, compact: AppConstants.spacingMedium, medium: AppConstants.spacingLarge, expanded: AppConstants.spacingLarge)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        '로그인',
                        style: TextStyle(color: AppColors.accent),
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
