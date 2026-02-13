import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 계정 설정 화면. 이메일 변경, 비밀번호 변경, 로그아웃, 계정 삭제.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _changeEmail(BuildContext context) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: EdgeInsets.only(
          left: AppConstants.paddingLarge,
          right: AppConstants.paddingLarge,
          top: AppConstants.paddingLarge,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppConstants.paddingLarge,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('이메일 변경', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: '새 이메일',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '새 이메일을 입력하세요.';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return '올바른 이메일 주소를 입력하세요.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: Colors.white.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          await FirebaseAuth.instance.currentUser?.updateEmail(emailController.text.trim());
                          if (mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이메일이 변경되었습니다.'), backgroundColor: AppColors.success));
                          }
                        } catch (e) {
                          setState(() => _errorMessage = '이메일 변경에 실패했습니다.');
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('계정 삭제', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          '정말 계정을 삭제하시겠습니까? 삭제된 계정은 복구할 수 없습니다.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('취소', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary))),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('로그인이 필요합니다.');
      await currentUser.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('계정이 삭제되었습니다.'), backgroundColor: AppColors.textSecondary));
        context.go('/login');
      }
    } catch (e) {
      setState(() => _errorMessage = '계정 삭제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF16162A);
    const surfaceLight = Color(0xFF1C1C34);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: '계정 설정'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsTile(
                    icon: Icons.email_outlined,
                    label: '이메일 변경',
                    color: AppColors.secondary,
                    onTap: () => _changeEmail(context),
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: '비밀번호 변경',
                    color: AppColors.accent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('비밀번호 변경 기능은 준비 중입니다.'), backgroundColor: AppColors.surface),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    color: AppColors.primary,
                    onTap: () async {
                      await Provider.of<AuthService>(context, listen: false).signOut();
                      if (mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    label: '계정 삭제',
                    color: AppColors.error,
                    onTap: () => _deleteAccount(context),
                    isDanger: true,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF16162A);
    const surfaceLight = Color(0xFF1C1C34);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [surface, surfaceLight, color.withOpacity(0.06)],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: isDanger ? AppColors.error : AppColors.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textSecondary.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
