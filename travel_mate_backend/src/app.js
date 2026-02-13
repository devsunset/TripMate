/**
 * TravelMate 백엔드 진입점
 * Express 서버 설정, 라우트 마운트, DB 동기화, Firebase 초기화를 수행합니다.
 */

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

const sequelize = require('./config/database');
const authMiddleware = require('./middlewares/authMiddleware');
const errorHandler = require('./middlewares/errorHandlingMiddleware');

// 라우트 모듈 (댓글/상호작용/신고 라우트 포함)
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const messageRoutes = require('./routes/messageRoutes');
const fcmRoutes = require('./routes/fcmRoutes');
const chatRoutes = require('./routes/chatRoutes');
const postRoutes = require('./routes/postRoutes');
const itineraryRoutes = require('./routes/itineraryRoutes');
const commentRoutes = require('./routes/commentRoutes');
const interactionRoutes = require('./routes/interactionRoutes');
const reportRoutes = require('./routes/reportRoutes');
const uploadRoutes = require('./routes/uploadRoutes');

// 모델 로드 (Sequelize 동기화 시 스키마 반영용)
const User = require('./models/user');
const UserProfile = require('./models/userProfile');
const Tag = require('./models/tag');
const UserProfileTag = require('./models/userProfileTag');
const PrivateMessage = require('./models/privateMessage');
const FcmToken = require('./models/fcmToken');
const ChatRoom = require('./models/chatRoom');
const PostCategory = require('./models/postCategory');
const Post = require('./models/post');
const Itinerary = require('./models/itinerary');
const ItineraryDay = require('./models/itineraryDay');
const ItineraryActivity = require('./models/itineraryActivity');
const Comment = require('./models/comment');
const Like = require('./models/like');
const Bookmark = require('./models/bookmark');
const Report = require('./models/report');

// 환경 변수 로드 (.env 경로: travel_mate_backend 루트 기준)
const envPath = path.resolve(__dirname, '../.env');
dotenv.config({ path: envPath });

const serviceAccountKeyPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY_PATH || './serviceAccountKey.json';
const serviceAccountPath = path.resolve(__dirname, '..', serviceAccountKeyPath);
if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    '[환경 설정] 서비스 계정 키 파일이 없습니다. .env의 FIREBASE_SERVICE_ACCOUNT_KEY_PATH 또는 travel_mate_backend/serviceAccountKey.json 을 확인하세요.'
  );
  process.exit(1);
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccountPath) });

const app = express();
// CORS: Flutter web (localhost:8080) 등에서 API 호출 허용. 401 등 모든 응답에 헤더 포함되도록 먼저 적용.
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// 업로드 이미지 정적 제공 (uploads/ 디렉터리)
const uploadsPath = path.resolve(__dirname, '../uploads');
app.use('/uploads', express.static(uploadsPath));

// API 라우트 마운트
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/fcm', fcmRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/itineraries', itineraryRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/interactions', interactionRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/upload', uploadRoutes);

/**
 * 인증 필요 테스트용 보호 라우트
 * Authorization: Bearer <Firebase ID Token> 필요
 */
app.get('/api/protected', authMiddleware, (req, res) => {
  res.json({ message: '보호된 라우트 접근 성공', user: req.user });
});

/**
 * 서버 상태 확인용 루트 경로
 */
app.get('/', (req, res) => {
  res.send('TravelMate Backend API is running!');
});

// 전역 에러 핸들러 (라우트 등록 후 마지막에 적용)
app.use(errorHandler);

// DB 동기화 후 서버 리스닝 (카테고리 등 초기 데이터는 DB에 이미 있음)
sequelize
  .sync({ alter: true })
  .then(() => {
    console.log('데이터베이스 동기화 완료');
  })
  .catch((err) => {
    console.error('데이터베이스 동기화 오류:', err);
  });

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`서버가 포트 ${PORT}에서 실행 중입니다.`);
});
