/// 앱 전역 상수(패딩, 간격, 테두리 반경, 앱명, 비밀번호/OTP 규칙, 애니메이션 시간).
class AppConstants {
  /// 백엔드 API 베이스 URL (이미지 업로드·REST 호출 공통). 에뮬레이터는 10.0.2.2:3000 사용 가능.
  static const String apiBaseUrl = 'http://localhost:3000';

  /// Google Sign-In **웹** 전용 OAuth 2.0 Web Client ID.
  static const String? googleSignInWebClientId = '926680717914-3ecqkndqufpch8pmjdr8cv8q8q077gll.apps.googleusercontent.com';

  static const double paddingExtraSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double borderRadius = 12.0;

  static const String appName = "TravelMate";
  static const int passwordMinLength = 6;
  static const int otpLength = 6;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
