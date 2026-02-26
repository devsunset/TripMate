import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';

/// 데이터 없음/에러 시 표시할 공통 빈 상태 위젯.
/// 아이콘 + 제목 + 부가 문구 + (선택) 버튼으로 이쁘게 표시.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isError = false,
    this.actionLabel,
    this.onAction,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primary;
    final isCompact = Responsive.isCompact(context);
    final horizontalPad = Responsive.value(context, compact: AppConstants.paddingMedium, medium: AppConstants.paddingLarge, expanded: AppConstants.paddingLarge);
    final iconSize = Responsive.value(context, compact: 96.0, medium: 120.0, expanded: 120.0);
    final innerIconSize = Responsive.value(context, compact: 44.0, medium: 56.0, expanded: 56.0);
    final titleFontSize = Responsive.value(context, compact: 16.0, medium: 18.0, expanded: 18.0);
    final spacing = Responsive.value(context, compact: 16.0, medium: 24.0, expanded: 28.0);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.35), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, size: innerIconSize, color: color),
              ),
              SizedBox(height: spacing),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                SizedBox(height: isCompact ? 6 : 8),
                Text(
                  subtitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: isCompact ? 20 : 28),
              if (isError && onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: isCompact ? 18 : 20),
                  label: const Text('다시 시도'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 24, vertical: isCompact ? 10 : 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                )
              else if (actionLabel != null && onAction != null)
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(Icons.add_rounded, size: isCompact ? 18 : 20),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 24, vertical: isCompact ? 10 : 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
