import 'package:flutter/material.dart';
import 'package:travel_mate_app/app/theme.dart';

/// 프로필 사진 또는 성별 기준 사람 모양 아이콘을 표시하는 공통 아바타.
/// - profileImageUrl 이 있으면 해당 이미지 표시 (로드 실패 시 성별/기본 아이콘으로 대체)
/// - 없으면 gender 기준: 남성=남자 모양(Icons.man), 여성=여자 모양(Icons.woman), 그 외=Icons.person
class ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String? gender;
  final double radius;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfileAvatar({
    super.key,
    this.profileImageUrl,
    this.gender,
    this.radius = 24,
    this.iconSize,
    this.backgroundColor,
    this.iconColor,
  });

  /// 성별에 따른 사람 모양 아이콘. 남성=남자 모양, 여성=여자 모양. 다른 화면에서 동일 기준 적용 시 사용.
  static IconData iconForGender(String? gender) {
    if (gender == null) return Icons.person;
    if (gender == '남성') return Icons.man;
    if (gender == '여성') return Icons.woman;
    return Icons.person;
  }

  static IconData _iconForGender(String? gender) => iconForGender(gender);

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final iconSizeActual = iconSize ?? (radius * 1.2);
    final hasImage = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;
    final icon = _iconForGender(gender);
    final color = iconColor ?? AppColors.primary;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary.withOpacity(0.2),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => Icon(icon, size: iconSizeActual, color: color),
              ),
            )
          : Icon(icon, size: iconSizeActual, color: color),
    );
  }
}
