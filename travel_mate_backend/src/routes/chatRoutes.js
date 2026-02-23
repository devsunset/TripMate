/** 채팅방: POST /api/chat/room (채팅 요청), GET /api/chat/rooms (내 채팅방 목록, 인증 필요) */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const chatController = require('../controllers/chatController');

router.use(authMiddleware);
router.get('/rooms', chatController.getMyChatRooms);
router.post('/room', chatController.createChatRoom);

module.exports = router;