import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/responsive.dart';

/// 공통 AppBar. 뒤로가기 버튼(가능할 때), 제목, 액션.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.value(context, compact: 20.0, medium: 22.0, expanded: 22.0);
    return AppBar(
      title: Text(title),
      backgroundColor: AppColors.background.withOpacity(0.85),
      scrolledUnderElevation: 8,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: iconSize, color: AppColors.textPrimary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              tooltip: '뒤로가기',
            )
          : null,
      actions: actions,
    );
  }
}
