/// 사용자 프로필 DTO(JSON 직렬화, fromJson/toJson)
import 'package:travel_mate_app/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.nickname,
    super.bio,
    super.profileImageUrl,
    super.gender,
    super.ageRange,
    super.travelStyles,
    super.interests,
    super.preferredDestinations,
  });

  /// 백엔드가 userId 등을 int로 보낼 수 있으므로 int/String 모두 허용.
  static String _toString(dynamic v) => v == null ? '' : (v is int ? v.toString() : v as String);
  static String? _toStringOrNull(dynamic v) => v == null ? null : (v is int ? v.toString() : v as String);
  static List<String> _toStringList(List<dynamic>? list) =>
      list?.map((e) => e == null ? '' : (e is int ? e.toString() : e as String)).toList() ?? const [];

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: _toString(json['userId']),
      nickname: _toString(json['nickname']),
      bio: _toStringOrNull(json['bio']),
      profileImageUrl: _toStringOrNull(json['profileImageUrl']),
      gender: _toStringOrNull(json['gender']),
      ageRange: _toStringOrNull(json['ageRange']),
      travelStyles: _toStringList((json['travelStyles'] as List<dynamic>?) ?? []),
      interests: _toStringList((json['interests'] as List<dynamic>?) ?? []),
      preferredDestinations: _toStringList((json['preferredDestinations'] as List<dynamic>?) ?? []),
    );
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      userId: entity.userId,
      nickname: entity.nickname,
      bio: entity.bio,
      profileImageUrl: entity.profileImageUrl,
      gender: entity.gender,
      ageRange: entity.ageRange,
      travelStyles: entity.travelStyles,
      interests: entity.interests,
      preferredDestinations: entity.preferredDestinations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      if (bio != null) 'bio': bio,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (gender != null) 'gender': gender,
      if (ageRange != null) 'ageRange': ageRange,
      'travelStyles': travelStyles,
      'interests': interests,
      'preferredDestinations': preferredDestinations,
    };
  }

  @override
  UserProfileModel copyWith({
    String? userId,
    String? nickname,
    String? bio,
    String? profileImageUrl,
    String? gender,
    String? ageRange,
    List<String>? travelStyles,
    List<String>? interests,
    List<String>? preferredDestinations,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      travelStyles: travelStyles ?? this.travelStyles,
      interests: interests ?? this.interests,
      preferredDestinations: preferredDestinations ?? this.preferredDestinations,
    );
  }
}