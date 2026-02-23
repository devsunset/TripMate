# TripMate (트래블 메이트)

여행 동반자 매칭 및 여행 정보 공유를 위한 모바일 커뮤니티 앱 프로젝트입니다. 사용자 식별자는 이메일(users PK=email)이며, 채팅은 상대에게 채팅 요청 후 신청한/신청받은 채팅방 목록에서 선택해 대화합니다. 프로필·게시글 상세에서 작성자에게 채팅 요청을 보낼 수 있습니다.

## 프로젝트 구성

| 디렉터리 | 설명 |
|----------|------|
| **travel_mate_app/** | Flutter 모바일 앱 (iOS / Android) |
| **travel_mate_backend/** | Node.js(Express) API 서버, MariaDB 연동 |
| **doc/** | 기획·기술 문서, DB 스키마, Firebase 연동 가이드 등 |

## 기술 스택

- **앱**: Flutter, Provider, Dio, GoRouter, Firebase Auth, Cloud Firestore(채팅), FCM
- **백엔드**: Node.js, Express, Sequelize, MariaDB, Firebase Admin(인증 검증), multer(이미지 업로드)
- **이미지 저장**: Firebase Storage 미사용. 프로필/게시글/일정 이미지는 백엔드에서 수신·저장 (uploads/, POST /api/upload/*)

## 사전 요구사항

- Flutter SDK (최신 안정 버전)
- Node.js LTS
- MariaDB
- Firebase 프로젝트 (Auth, Firestore 사용. Storage는 사용하지 않음)

## 빠른 실행

### 1. 백엔드

```bash
cd travel_mate_backend
cp .env.example .env
npm install
node src/app.js
```

자세한 설정은 travel_mate_backend/README.md 참고.

### 2. 앱

```bash
cd travel_mate_app
flutter pub get
flutter run
```

앱에서 사용하는 API 베이스 URL은 lib/app/constants.dart 의 AppConstants.apiBaseUrl 에서 변경할 수 있습니다. 에뮬레이터는 http://10.0.2.2:3000 등을 사용할 수 있습니다.

자세한 설정은 travel_mate_app/README.md 참고.

### 3. 데이터베이스

MariaDB에 스키마 생성이 필요하면 doc/travel_mate.sql 을 실행하세요.

## 문서

- **doc/firebase.txt** — Firebase 연동 상세 가이드 (Auth, Firestore. Storage 미사용 명시)
- **doc/travel_mate.sql** — MariaDB 스키마 및 시드 데이터 (users PK=email, chat_rooms.createdByUserId, posts.content LONGTEXT 등)
- **doc/trd.md** — 기술 요구사항 문서
- **doc/prd.md** — 제품 요구사항 문서
- **doc/firstvibe.json** — 초기 기획 QA 및 구현 요약
- **doc/todo.yaml** — 작업 목록 및 구현 가이드

## 라이선스

ISC (프로젝트 설정에 따름)
