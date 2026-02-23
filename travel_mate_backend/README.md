# TravelMate Backend

TripMate(트래블 메이트) Node.js API 서버. 사용자 식별자는 이메일(users PK=email). 사용자·프로필, 게시글, 일정, 댓글, 좋아요/북마크, 쪽지, 채팅방, FCM 토큰 등 REST API 제공. **이미지 파일은 multer로 수신하여 서버 `uploads/` 디렉터리에 저장**합니다 (Firebase Storage 미사용).

## 기술 스택

- **Node.js** (LTS)
- **Express**
- **Sequelize** + MariaDB
- **Firebase Admin SDK** — ID 토큰 검증
- **multer** — 이미지 업로드 (multipart/form-data)

## 사전 요구사항

- Node.js LTS
- MariaDB (스키마는 `doc/travel_mate.sql` 참고)
- Firebase 서비스 계정 키 JSON (Auth 검증용)

## 설치 및 실행

```bash
npm install
cp .env.example .env
# .env 편집 후
node src/app.js
```

기본 포트: `3000` (`.env`의 `PORT`로 변경 가능)

## 환경 변수 (.env)

| 변수 | 설명 |
|------|------|
| `PORT` | 서버 포트 (기본 3000) |
| `FIREBASE_SERVICE_ACCOUNT_KEY_PATH` | Firebase 서비스 계정 키 JSON 경로 (프로젝트 루트 기준) |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | MariaDB 연결 정보 |

## API 개요

- **인증**: `POST /api/auth/register`, `POST /api/auth/login` (Firebase ID 토큰 사용)
- **사용자/프로필**: `GET/PATCH /api/users/:userId/profile` (userId=이메일), `POST /api/users/:userId/profile/image`
- **이미지 업로드**: 아래 참고
- **채팅**: `GET /api/chat/rooms` (내 채팅방 목록, 신청한/신청받은 구분), `POST /api/chat/room` (채팅 요청, body: `{ partnerId: 이메일 }`)
- **게시글**: `GET/POST /api/posts`, `GET/PATCH/DELETE /api/posts/:id` (authorId=이메일)
- **일정**: `GET/POST /api/itineraries`, `GET/PATCH/DELETE /api/itineraries/:id`
- **댓글, 좋아요, 북마크, 쪽지, FCM 토큰, 신고 등**: 각각 `/api/comments`, `/api/interactions`, `/api/messages`, `/api/fcm`, `/api/reports` 등

대부분 보호된 라우트는 `Authorization: Bearer <Firebase ID Token>` 필요.

## 이미지 업로드 API (백엔드 저장)

| 메서드 | 경로 | 설명 | multipart 필드 |
|--------|------|------|----------------|
| POST | `/api/upload/profile` | 프로필 이미지 | `image` |
| POST | `/api/upload/post` | 게시글 이미지 | `image` |
| POST | `/api/upload/itinerary` | 일정 이미지 | `image` |

- 인증 필수. 저장 경로: `uploads/profile|posts|itineraries/{uid}/{timestamp}.jpg`
- 응답: `{ "message": "...", "imageUrl": "http(s)://host/uploads/..." }`
- 업로드 파일은 `/uploads` 경로로 정적 제공됨 (express.static)

## 디렉터리 구조

```
src/
├── app.js              # Express 앱, 라우트·정적 파일 마운트
├── config/             # DB 설정
├── controllers/        # 요청 핸들러 (uploadController 포함)
├── middlewares/       # authMiddleware, errorHandling
├── models/            # Sequelize 모델
├── routes/            # uploadRoutes, userRoutes, postRoutes 등
└── services/          # 알림 등
uploads/               # 이미지 저장 디렉터리 (실행 시 생성, .gitignore 권장)
```

## DB 스키마

초기 스키마 및 시드 데이터: 프로젝트 루트 **doc/travel_mate.sql** 참고.

## 라이선스

ISC
