import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';

/// 신고 대상 종류(사용자, 게시글, 일정, 댓글).
enum ReportEntityType { user, post, itinerary, comment }

/// 신고 버튼 위젯. 탭 시 신고 작성 화면으로 이동. reporterUserId는 백엔드 사용자 ID 사용.
class ReportButtonWidget extends StatelessWidget {
  final ReportEntityType entityType;
  final String entityId;
  final String? reporterUserId;

  const ReportButtonWidget({
    super.key,
    required this.entityType,
    required this.entityId,
    this.reporterUserId,
  });

  Future<void> _showReportDialog(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = await authService.getCurrentBackendUserId();
    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고하려면 로그인하세요.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    context.go(
      '/report',
      extra: {
        'entityType': entityType,
        'entityId': entityId,
        'reporterUserId': userId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag),
      color: AppColors.grey,
      onPressed: () async => _showReportDialog(context),
    );
  }
}
