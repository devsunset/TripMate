import 'package:flutter/material.dart';

/// 모바일·태블릿 반응형 브레이크포인트 및 공통 값.
/// - compact: 세로 기준 ~568, 가로 ~360 (작은 폰)
/// - medium: ~820 (일반 폰·작은 태블릿)
/// - expanded: 그 이상 (태블릿·가로 모드)
class Responsive {
  static const double breakpointCompact = 360;
  static const double breakpointMedium = 600;
  static const double breakpointExpanded = 900;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static bool isCompact(BuildContext context) => width(context) < breakpointMedium;
  static bool isMedium(BuildContext context) {
    final w = width(context);
    return w >= breakpointMedium && w < breakpointExpanded;
  }

  static bool isExpanded(BuildContext context) => width(context) >= breakpointExpanded;

  /// 화면 너비 기준 compact / medium / expanded 에 따라 값 선택.
  static T value<T>(BuildContext context, {required T compact, T? medium, T? expanded}) {
    final w = width(context);
    if (w >= breakpointExpanded && expanded != null) return expanded;
    if (w >= breakpointMedium && medium != null) return medium;
    return compact;
  }

  /// 세로 높이 기준으로 작은/중간/큰 화면 값 선택 (폰 세로 짧음 대응).
  static T valueByHeight<T>(BuildContext context, {required T compact, T? medium, T? expanded}) {
    final h = height(context);
    if (h >= 800 && expanded != null) return expanded;
    if (h >= 640 && medium != null) return medium;
    return compact;
  }

  /// 패딩: 화면 너비에 따라 좌우 패딩 (작은 화면에서 더 줄임).
  static EdgeInsets paddingHorizontal(BuildContext context, {double? compact, double? medium, double? expanded}) {
    final w = width(context);
    double pad;
    if (w >= breakpointExpanded && expanded != null) {
      pad = expanded;
    } else if (w >= breakpointMedium && medium != null) {
      pad = medium;
    } else {
      pad = compact ?? 16;
    }
    return EdgeInsets.symmetric(horizontal: pad);
  }

  /// 리스트·그리드용 좌우 마진과 셀 개수 (1열=모바일, 2열=태블릿 등).
  static int listCrossAxisCount(BuildContext context) => value(context, compact: 1, medium: 2, expanded: 3);

  /// 최대 콘텐츠 너비 (큰 화면에서도 읽기 편한 폭 제한).
  static double maxContentWidth(BuildContext context) => value(context, compact: width(context), medium: 560, expanded: 680);
}
