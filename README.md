# TravelMate (트래블 메이트)

여행 동반자 매칭 및 여행 정보 공유를 위한 모바일 커뮤니티 앱 프로젝트입니다. 사용자 식별자는 백엔드 랜덤 영숫자 ID(users PK=id)이며 이메일은 수집·저장하지 않습니다. 채팅은 상대에게 채팅 요청 후 신청한/신청받은 채팅방 목록에서 선택해 대화합니다. 프로필·게시글 상세에서 작성자에게 채팅 요청을 보낼 수 있습니다.

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

- **최초 생성·초기화**: `doc/travel_mate.sql`을 DB에 적용해 스키마와 시드 데이터를 만듭니다.
  - **방법 A (프로젝트 루트)**: `bash scripts/init-db.sh` — `travel_mate_backend/.env`의 `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`를 읽어 MariaDB/MySQL 클라이언트로 SQL 실행.
  - **방법 B (백엔드 폴더)**: `npm run init-db` 또는 `node scripts/init-db.js` — 동일 .env를 사용해 Node(mariadb 드라이버)로 SQL 실행.
- 수동 실행: MariaDB 클라이언트에서 `mysql -h 호스트 -u 사용자 -p < doc/travel_mate.sql` 로 적용 가능.

## 문서

- **doc/firebase.txt** — Firebase 연동 상세 가이드 (Auth, Firestore. Storage 미사용 명시)
- **doc/travel_mate.sql** — MariaDB 스키마 및 시드 데이터 (최초 생성 시 itineraries.description 포함 LONGTEXT, users PK=id 랜덤 영숫자, 이메일 미저장, chat_rooms.createdByUserId, posts.content LONGTEXT 등)
- **test.txt** — API 전체 경우의 수별 curl 호출 예시 및 기대 응답 정리
- **doc/trd.md** — 기술 요구사항 문서
- **doc/prd.md** — 제품 요구사항 문서
- **doc/firstvibe.json** — 초기 기획 QA 및 구현 요약
- **doc/todo.yaml** — 작업 목록 및 구현 가이드

## 라이선스

ISC (프로젝트 설정에 따름)
