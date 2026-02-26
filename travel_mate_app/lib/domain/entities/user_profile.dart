/// 사용자 프로필 엔티티(닉네임, 소개, 이미지, 성별, 연령대, 여행스타일·관심사·선호지역 등).
library;
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String nickname;
  final String? bio;
  final String? profileImageUrl;
  final String? gender;
  final String? ageRange;
  final List<String> travelStyles;
  final List<String> interests;
  final List<String> preferredDestinations;

  const UserProfile({
    required this.userId,
    required this.nickname,
    this.bio,
    this.profileImageUrl,
    this.gender,
    this.ageRange,
    this.travelStyles = const [],
    this.interests = const [],
    this.preferredDestinations = const [],
  });

  UserProfile copyWith({
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
    return UserProfile(
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

  @override
  List<Object?> get props => [
        userId,
        nickname,
        bio,
        profileImageUrl,
        gender,
        ageRange,
        travelStyles,
        interests,
        preferredDestinations,
      ];
}