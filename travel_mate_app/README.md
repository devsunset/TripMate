# TravelMate App

TripMate(트래블 메이트) Flutter 모바일 앱. 여행 동반자 검색, 1:1 채팅(채팅 요청 후 신청한/신청받은 채팅방 목록에서 선택해 대화), 커뮤니티 게시판·게시글 상세(작성자에게 채팅 요청), 여행 일정 공유.

## 기술 스택

- Flutter (최신 안정 버전)
- 상태 관리: Provider
- 라우팅: GoRouter
- HTTP: Dio
- Firebase: Auth, Cloud Firestore(실시간 채팅), FCM(푸시)
- 이미지: image_picker, flutter_image_compress. 업로드는 백엔드 API로 전송 (Firebase Storage 미사용)

## 사전 요구사항

- Flutter SDK 설치
- Firebase 프로젝트 설정 (Auth, Firestore 활성화)
- flutterfire configure 실행 후 lib/firebase_options.dart 생성

자세한 Firebase 연동 절차는 프로젝트 루트의 doc/firebase.txt 를 참고하세요.

## 환경 설정

### API 베이스 URL

백엔드 서버 주소는 lib/app/constants.dart 에서 설정합니다.

- 기본: http://localhost:3000
- 실제 기기: PC IP 사용 (예: http://192.168.0.10:3000)
- Android 에뮬레이터: http://10.0.2.2:3000

### 이미지 업로드

프로필·게시글·일정 이미지는 앱에서 압축 후 백엔드 다음 API로 전송합니다.

- POST /api/upload/profile — 프로필 사진
- POST /api/upload/post — 게시글 이미지
- POST /api/upload/itinerary — 일정 이미지

multipart 필드명: image. 인증 헤더 Authorization: Bearer (Firebase ID Token) 필요.

## 실행

### 모바일 (Android / iOS)

```bash
flutter pub get
flutter run
```

### 웹 (로컬에서 Firefox 등 브라우저로 확인)

```bash
flutter pub get
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

실행 후 터미널에 표시되는 주소(예: `http://localhost:8080`)를 **Firefox** 또는 Chrome 등 브라우저에서 열면 됩니다. 같은 PC에서는 `http://localhost:8080`, 다른 기기에서는 `http://<이 PC의 IP>:8080`으로 접속할 수 있습니다.

## 프로젝트 구조 (요약)

- lib/app/ — 라우터, 테마, 상수(apiBaseUrl 등)
- lib/core/ — Auth, FCM 등 공통 서비스
- lib/data/ — 데이터소스, 모델, 레포지토리 구현
- lib/domain/ — 엔티티, 레포지토리 인터페이스, 유스케이스
- lib/presentation/ — 화면 및 공통 위젯
- lib/main.dart, lib/firebase_options.dart

## 라이선스

ISC
