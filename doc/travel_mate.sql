CREATE DATABASE IF NOT EXISTS `travel_mate` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `travel_mate`;

-- 기존 테이블 삭제 (존재 시에만 삭제, FK 검사 일시 비활성화)
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `reports`;
DROP TABLE IF EXISTS `fcm_tokens`;
DROP TABLE IF EXISTS `private_messages`;
DROP TABLE IF EXISTS `chat_rooms`;
DROP TABLE IF EXISTS `bookmarks`;
DROP TABLE IF EXISTS `likes`;
DROP TABLE IF EXISTS `comments`;
DROP TABLE IF EXISTS `itinerary_activities`;
DROP TABLE IF EXISTS `itinerary_days`;
DROP TABLE IF EXISTS `posts`;
DROP TABLE IF EXISTS `itineraries`;
DROP TABLE IF EXISTS `user_profile_tags`;
DROP TABLE IF EXISTS `user_profiles`;
DROP TABLE IF EXISTS `tags`;
DROP TABLE IF EXISTS `post_categories`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- TravelMate 데이터베이스 스키마
-- 데이터베이스: MariaDB
-- 인코딩: utf8mb4
-- 최종 업데이트: 2026-02-12
--
-- [사용자 식별자] users 테이블의 Primary Key는 랜덤 영문·숫자 조합 id입니다.
-- 이메일은 수집·저장하지 않습니다. 모든 사용자 FK(userId, authorId 등)는 users.id를 참조합니다.
--
-- [이미지 URL] 프로필/게시글/일정 이미지는 백엔드(Node.js)에서 수신·저장합니다.
-- POST /api/upload/profile, /api/upload/post, /api/upload/itinerary 반환 URL을 각 테이블에 저장합니다.

-- -----------------------------------------------------
-- Table `users` (사용자 식별자 = 랜덤 id, PK)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(32) NOT NULL COMMENT '사용자 ID (Primary Key, 랜덤 영문·숫자 조합)',
  `firebase_uid` VARCHAR(255) NOT NULL UNIQUE COMMENT 'Firebase 인증 UID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '가입일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '마지막 정보 수정일',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자 기본 정보. id(PK)는 랜덤 영문·숫자 조합, 이메일 미저장.';


-- -----------------------------------------------------
-- Table `user_profiles`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_profiles` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '프로필 고유 ID (Primary Key)',
  `userId` VARCHAR(32) NOT NULL UNIQUE COMMENT '사용자 ID (users.id FK)',
  `nickname` VARCHAR(255) NOT NULL UNIQUE COMMENT '사용자 닉네임',
  `bio` TEXT COMMENT '자기소개',
  `profileImageUrl` VARCHAR(512) COMMENT '프로필 이미지 URL (백엔드 POST /api/upload/profile 반환 URL). 긴 URL 대비 512 권장.',
  `gender` VARCHAR(50) COMMENT '성별 (Male, Female, Other 등)',
  `ageRange` VARCHAR(50) COMMENT '연령대 (20s, 30s 등)',
  `travelStyles` JSON COMMENT '여행 스타일 태그 목록 (JSON 배열)',
  `interests` JSON COMMENT '관심사 태그 목록 (JSON 배열)',
  `preferredDestinations` JSON COMMENT '선호 지역 목록 (JSON 배열)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '프로필 생성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '프로필 마지막 수정일',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_user_profiles_users`
    FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  INDEX `idx_gender_ageRange` (`gender`, `ageRange`) COMMENT '성별, 연령대 복합 인덱스 (동행 찾기 필터용)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자 프로필 정보. 닉네임, 소개, 여행 스타일 등 확장 정보를 저장합니다.';


-- -----------------------------------------------------
-- Table `post_categories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `post_categories` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '카테고리 고유 ID',
  `name` VARCHAR(255) NOT NULL UNIQUE COMMENT '카테고리 이름 (예: 질문, 팁, 후기)',
  `description` TEXT COMMENT '카테고리 설명',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '커뮤니티 게시글 카테고리 분류 테이블';


-- -----------------------------------------------------
-- Table `tags`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `tags` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '태그 고유 ID',
  `name` VARCHAR(255) NOT NULL UNIQUE COMMENT '태그 이름',
  `type` VARCHAR(255) NOT NULL COMMENT '태그 타입 (예: travel_style, interest)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (`id`),
  INDEX `idx_type` (`type`) COMMENT '태그 타입별 검색을 위한 인덱스'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '여행 스타일, 관심사 등 각종 태그 정보를 저장하는 테이블';


-- -----------------------------------------------------
-- Table `user_profile_tags`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_profile_tags` (
  `userProfileId` INT NOT NULL COMMENT 'user_profiles 테이블 외래 키',
  `tagId` INT NOT NULL COMMENT 'tags 테이블 외래 키',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userProfileId`, `tagId`),
  CONSTRAINT `fk_user_profile_tags_profiles`
    FOREIGN KEY (`userProfileId`)
    REFERENCES `user_profiles` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_user_profile_tags_tags`
    FOREIGN KEY (`tagId`)
    REFERENCES `tags` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자 프로필과 태그의 N:M 매핑 테이블';


-- -----------------------------------------------------
-- Table `itineraries`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `itineraries` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '일정 고유 ID',
  `authorId` VARCHAR(32) NOT NULL COMMENT '작성자 사용자 ID (users.id)',
  `title` VARCHAR(255) NOT NULL COMMENT '일정 제목',
  `description` LONGTEXT NOT NULL COMMENT '일정 상세 설명 (웹 에디터 본문, 커뮤니티 게시글과 동일)',
  `startDate` DATE NOT NULL COMMENT '여행 시작일',
  `endDate` DATE NOT NULL COMMENT '여행 종료일',
  `imageUrls` JSON COMMENT '대표 이미지 URL 목록 (백엔드 /api/upload/itinerary 반환 URL 배열)',
  `mapData` JSON COMMENT '지도 관련 데이터 (마커, 경로 등, JSON)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (`id`),
  INDEX `idx_authorId` (`authorId`),
  INDEX `idx_dates` (`startDate`, `endDate`) COMMENT '기간 검색을 위한 인덱스',
  CONSTRAINT `fk_itineraries_users`
    FOREIGN KEY (`authorId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자가 작성한 여행 일정의 기본 정보';


-- -----------------------------------------------------
-- Table `posts`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `posts` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '게시글 고유 ID',
  `authorId` VARCHAR(32) NOT NULL COMMENT '작성자 사용자 ID (users.id)',
  `categoryId` INT NOT NULL COMMENT '카테고리 (post_categories.id)',
  `title` VARCHAR(255) NOT NULL COMMENT '게시글 제목',
  `content` LONGTEXT NOT NULL COMMENT '게시글 본문 (CLOB, 대용량 텍스트)',
  `imageUrls` JSON COMMENT '첨부 이미지 URL 목록 (백엔드 /api/upload/post 반환 URL 배열)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (`id`),
  INDEX `idx_authorId` (`authorId`),
  INDEX `idx_categoryId` (`categoryId`),
  CONSTRAINT `fk_posts_users`
    FOREIGN KEY (`authorId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_posts_categories`
    FOREIGN KEY (`categoryId`)
    REFERENCES `post_categories` (`id`)
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '커뮤니티 게시글 정보';


-- -----------------------------------------------------
-- Table `itinerary_days`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `itinerary_days` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '일차 고유 ID',
  `itineraryId` INT NOT NULL COMMENT '일정 (itineraries.id)',
  `dayNumber` INT NOT NULL COMMENT '일차 번호 (1, 2, ...)',
  `date` DATE NOT NULL COMMENT '해당 일차의 실제 날짜',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_itinerary_day` (`itineraryId`, `dayNumber`),
  CONSTRAINT `fk_itinerary_days_itineraries`
    FOREIGN KEY (`itineraryId`)
    REFERENCES `itineraries` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '여행 일정의 각 일차별 정보';


-- -----------------------------------------------------
-- Table `itinerary_activities`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `itinerary_activities` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '활동 고유 ID',
  `itineraryDayId` INT NOT NULL COMMENT '일차 (itinerary_days.id)',
  `time` VARCHAR(255) COMMENT '활동 시간 (예: 09:00, 점심)',
  `description` TEXT NOT NULL COMMENT '활동 내용',
  `location` VARCHAR(255) COMMENT '장소 이름',
  `coordinates` JSON COMMENT '좌표 정보 {latitude, longitude}',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_itineraryDayId` (`itineraryDayId`),
  CONSTRAINT `fk_itinerary_activities_days`
    FOREIGN KEY (`itineraryDayId`)
    REFERENCES `itinerary_days` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '각 일차에 포함된 세부 활동 정보';


-- -----------------------------------------------------
-- Table `comments`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `comments` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '댓글 고유 ID',
  `authorId` VARCHAR(32) NOT NULL COMMENT '작성자 사용자 ID (users.id)',
  `postId` INT COMMENT '관련 게시글 (posts.id)',
  `itineraryId` INT COMMENT '관련 일정 (itineraries.id)',
  `parentCommentId` INT COMMENT '부모 댓글 ID (대댓글용)',
  `content` TEXT NOT NULL COMMENT '댓글 내용',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (`id`),
  INDEX `idx_authorId` (`authorId`),
  INDEX `idx_postId_created_at` (`postId`, `created_at`) COMMENT '게시글별 댓글 목록 정렬용',
  INDEX `idx_itineraryId_created_at` (`itineraryId`, `created_at`) COMMENT '일정별 댓글 목록 정렬용',
  INDEX `idx_parentCommentId` (`parentCommentId`),
  CONSTRAINT `fk_comments_users`
    FOREIGN KEY (`authorId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_comments_posts`
    FOREIGN KEY (`postId`)
    REFERENCES `posts` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_comments_itineraries`
    FOREIGN KEY (`itineraryId`)
    REFERENCES `itineraries` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_comments_parent`
    FOREIGN KEY (`parentCommentId`)
    REFERENCES `comments` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '게시글 또는 일정에 대한 댓글 및 대댓글';


-- -----------------------------------------------------
-- Table `likes` (대리 키 id + 유니크로 post만/일정만 좋아요 시 NULL 삽입 가능)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `likes` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '좋아요 고유 ID (Primary Key)',
  `userId` VARCHAR(32) NOT NULL COMMENT '사용자 ID (users.id)',
  `postId` INT COMMENT '게시글 (posts.id)',
  `itineraryId` INT COMMENT '일정 (itineraries.id)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_likes_user_post` (`userId`, `postId`),
  UNIQUE KEY `uq_likes_user_itinerary` (`userId`, `itineraryId`),
  INDEX `idx_postId` (`postId`),
  INDEX `idx_itineraryId` (`itineraryId`),
  CONSTRAINT `fk_likes_users`
    FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_likes_posts`
    FOREIGN KEY (`postId`)
    REFERENCES `posts` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_likes_itineraries`
    FOREIGN KEY (`itineraryId`)
    REFERENCES `itineraries` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자의 좋아요 정보 (게시글 또는 일정)';


-- -----------------------------------------------------
-- Table `bookmarks` (대리 키 id + 유니크로 post만/일정만 북마크 시 NULL 삽입 가능)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `bookmarks` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '북마크 고유 ID (Primary Key)',
  `userId` VARCHAR(32) NOT NULL COMMENT '사용자 ID (users.id)',
  `postId` INT COMMENT '게시글 (posts.id)',
  `itineraryId` INT COMMENT '일정 (itineraries.id)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bookmarks_user_post` (`userId`, `postId`),
  UNIQUE KEY `uq_bookmarks_user_itinerary` (`userId`, `itineraryId`),
  INDEX `idx_postId` (`postId`),
  INDEX `idx_itineraryId` (`itineraryId`),
  CONSTRAINT `fk_bookmarks_users`
    FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_bookmarks_posts`
    FOREIGN KEY (`postId`)
    REFERENCES `posts` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_bookmarks_itineraries`
    FOREIGN KEY (`itineraryId`)
    REFERENCES `itineraries` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자의 북마크 정보 (게시글 또는 일정)';


-- -----------------------------------------------------
-- Table `chat_rooms`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat_rooms` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `firestoreChatId` VARCHAR(255) NOT NULL UNIQUE COMMENT 'Firestore 채팅방 ID (두 사용자 id 정렬 후 _ 연결)',
  `user1Id` VARCHAR(32) NOT NULL COMMENT '참여자1 사용자 ID (users.id)',
  `user2Id` VARCHAR(32) NOT NULL COMMENT '참여자2 사용자 ID (users.id)',
  `createdByUserId` VARCHAR(32) NULL COMMENT '채팅을 신청한 사용자 ID (user1Id 또는 user2Id)',
  `lastMessage` TEXT COMMENT '마지막 메시지 요약',
  `lastMessageSentAt` DATETIME COMMENT '마지막 메시지 전송 시간',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_chat_users` (`user1Id`, `user2Id`),
  INDEX `idx_lastMessageSentAt` (`lastMessageSentAt`) COMMENT '채팅방 목록 정렬용 인덱스',
  CONSTRAINT `fk_chat_rooms_user1`
    FOREIGN KEY (`user1Id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_chat_rooms_user2`
    FOREIGN KEY (`user2Id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_chat_rooms_created_by`
    FOREIGN KEY (`createdByUserId`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '1:1 채팅방 정보. createdByUserId=채팅 신청자, 상대는 신청받은 쪽.';


-- -----------------------------------------------------
-- Table `private_messages`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `private_messages` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `senderId` VARCHAR(32) NOT NULL COMMENT '보내는 사람 사용자 ID (users.id)',
  `receiverId` VARCHAR(32) NOT NULL COMMENT '받는 사람 사용자 ID (users.id)',
  `content` TEXT NOT NULL COMMENT '쪽지 내용',
  `isRead` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '수신자 읽음 여부 (0: 안읽음, 1: 읽음)',
  `sent_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '전송 시간',
  PRIMARY KEY (`id`),
  INDEX `idx_senderId` (`senderId`),
  INDEX `idx_receiverId_isRead_sent_at` (`receiverId`, `isRead`, `sent_at`) COMMENT '수신함 목록 조회 및 정렬용',
  CONSTRAINT `fk_private_messages_sender`
    FOREIGN KEY (`senderId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_private_messages_receiver`
    FOREIGN KEY (`receiverId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '사용자 간 1:1 쪽지';


-- -----------------------------------------------------
-- Table `fcm_tokens`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `fcm_tokens` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `userId` VARCHAR(32) NOT NULL COMMENT '사용자 ID (users.id)',
  `token` VARCHAR(255) NOT NULL COMMENT 'FCM 디바이스 토큰',
  `deviceType` VARCHAR(50) COMMENT '디바이스 종류 (android, ios, web)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_token` (`userId`, `token`),
  INDEX `idx_userId` (`userId`),
  CONSTRAINT `fk_fcm_tokens_users`
    FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '푸시 알림을 위한 사용자별 FCM 디바이스 토큰';


-- -----------------------------------------------------
-- Table `reports`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `reports` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `reporterUserId` VARCHAR(32) NOT NULL COMMENT '신고자 사용자 ID (users.id)',
  `reportedUserId` VARCHAR(32) COMMENT '신고된 사용자 ID (users.id)',
  `reportedPostId` INT COMMENT '신고된 게시글 (posts.id)',
  `reportedItineraryId` INT COMMENT '신고된 일정 (itineraries.id)',
  `reportedCommentId` INT COMMENT '신고된 댓글 (comments.id)',
  `reportType` VARCHAR(255) NOT NULL COMMENT '신고 유형 (스팸, 혐오 발언 등)',
  `reason` TEXT COMMENT '신고 사유 (기타 선택 시)',
  `status` VARCHAR(50) NOT NULL DEFAULT 'pending' COMMENT '처리 상태 (pending, resolved, rejected)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_status` (`status`) COMMENT '처리 상태별 신고 목록 조회용',
  UNIQUE KEY `uq_report_user_to_user` (`reporterUserId`, `reportedUserId`),
  UNIQUE KEY `uq_report_user_to_post` (`reporterUserId`, `reportedPostId`),
  UNIQUE KEY `uq_report_user_to_itinerary` (`reporterUserId`, `reportedItineraryId`),
  UNIQUE KEY `uq_report_user_to_comment` (`reporterUserId`, `reportedCommentId`),
  CONSTRAINT `fk_reports_reporter`
    FOREIGN KEY (`reporterUserId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reported_user`
    FOREIGN KEY (`reportedUserId`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reported_post`
    FOREIGN KEY (`reportedPostId`)
    REFERENCES `posts` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reported_itinerary`
    FOREIGN KEY (`reportedItineraryId`)
    REFERENCES `itineraries` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reported_comment`
    FOREIGN KEY (`reportedCommentId`)
    REFERENCES `comments` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT = '컨텐츠 및 사용자에 대한 신고 내역';

-- -----------------------------------------------------
-- Seed Data
-- -----------------------------------------------------

-- Insert initial data into `post_categories`
INSERT INTO `post_categories` (`id`, `name`, `description`) VALUES
(1, '자유 게시판', '자유롭게 여행 관련 이야기를 나누는 공간입니다.'),
(2, '여행 후기', '다녀온 여행에 대한 생생한 후기를 공유하는 공간입니다.'),
(3, '여행 질문', '여행 준비나 도중 궁금한 점을 질문하고 답변하는 공간입니다.'),
(4, '동행 찾기', '함께 여행할 동반자를 찾는 공간입니다.'),
(5, '여행 팁', '유용한 여행 정보와 팁을 공유하는 공간입니다.');


-- Insert initial data into `tags`
INSERT INTO `tags` (`id`, `name`, `type`) VALUES
-- Travel Styles
(101, '액티비티', 'travel_style'),
(102, '힐링', 'travel_style'),
(103, '미식', 'travel_style'),
(104, '문화 탐방', 'travel_style'),
(105, '가족 여행', 'travel_style'),
(106, '혼자 여행', 'travel_style'),
(107, '우정 여행', 'travel_style'),
(108, '쇼핑', 'travel_style'),
(109, '자연', 'travel_style'),
(110, '도시', 'travel_style'),

-- Interests
(201, '사진', 'interest'),
(202, '하이킹', 'interest'),
(203, '스쿠버다이빙', 'interest'),
(204, '서핑', 'interest'),
(205, '음악', 'interest'),
(206, '미술', 'interest'),
(207, '역사', 'interest'),
(208, '영화', 'interest'),
(209, '독서', 'interest'),
(210, '봉사활동', 'interest'),

-- Preferred Destinations (Regions)
(301, '유럽', 'preferred_destination'),
(302, '아시아', 'preferred_destination'),
(303, '북미', 'preferred_destination'),
(304, '남미', 'preferred_destination'),
(305, '아프리카', 'preferred_destination'),
(306, '오세아니아', 'preferred_destination');
