/// 앱 전역 상수(패딩, 간격, 테두리 반경, 앱명, 비밀번호/OTP 규칙, 애니메이션 시간).
class AppConstants {
  static String _apiBaseUrl = 'http://localhost:3000'; // 기본값 (개발 환경)
  static String? _googleSignInWebClientId = '926680717914-3ecqkndqufpch8pmjdr8cv8q8q077gll.apps.googleusercontent.com'; // 기본값 (개발 환경)

  // API 베이스 URL (이미지 업로드·REST 호출 공통). 에뮬레이터는 10.0.2.2:3000 사용 가능.
  static String get apiBaseUrl => _apiBaseUrl;
  // Google Sign-In **웹** 전용 OAuth 2.0 Web Client ID.
  static String? get googleSignInWebClientId => _googleSignInWebClientId;

  static void setApiBaseUrl(String url) {
    _apiBaseUrl = url;
  }

  static void setGoogleSignInWebClientId(String? clientId) {
    _googleSignInWebClientId = clientId;
  }


  static const double paddingExtraSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double spacingExtraSmall = 4.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double cardRadiusLarge = 24.0;

  /// 반응형용: 작은 화면에서 더 줄인 간격 (Responsive.value 등과 함께 사용).
  static const double paddingMediumCompact = 12.0;
  static const double paddingLargeCompact = 16.0;
  static const double spacingMediumCompact = 12.0;
  static const double spacingLargeCompact = 20.0;

  static const String appName = "TravelMate";
  static const int passwordMinLength = 8;
  static const int otpLength = 6;
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// 메인 화면 카드 섹션별 배경 이미지 (동행 찾기, 채팅, 커뮤니티, 일정). 상세 화면 배경으로 전달.
  static const List<String> sectionBackgroundImages = [
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400', // 동행
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400', // 채팅
    'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=400', // 커뮤니티
    'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400', // 일정
  ];
}
