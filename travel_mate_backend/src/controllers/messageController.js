/**
 * 1:1 쪽지 컨트롤러
 * 쪽지 발송 시 수신자에게 FCM 알림 전송.
 */
const admin = require('firebase-admin');
const PrivateMessage = require('../models/privateMessage');
const User = require('../models/user');
const UserProfile = require('../models/userProfile');
const NotificationService = require('../services/notificationService');
const { LIMITS, checkMaxLength } = require('../utils/fieldLimits');

/** 쪽지 발송: DB 저장 후 수신자에게 FCM 푸시 발송 */
exports.sendPrivateMessage = async (req, res, next) => {
  try {
    const { receiverId, content } = req.body;
    const senderFirebaseUid = req.user.uid;

    if (!receiverId || !content) {
      return res.status(400).json({ message: '수신자 ID와 내용이 필요합니다.' });
    }
    const contentErr = checkMaxLength(content, LIMITS.messageContent, '쪽지 내용');
    if (contentErr) return res.status(400).json({ message: contentErr });

    const sender = await User.findOne({ where: { firebase_uid: senderFirebaseUid } });
    const receiver = await User.findOne({ where: { email: receiverId } });

    if (!sender || !receiver) {
      return res.status(404).json({ message: '발신자 또는 수신자를 찾을 수 없습니다.' });
    }

    const message = await PrivateMessage.create({
      senderId: sender.email,
      receiverId: receiver.email,
      content,
    });

    const senderProfile = await UserProfile.findOne({ where: { userId: sender.email } });
    const senderNickname = senderProfile ? senderProfile.nickname : senderFirebaseUid;

    await NotificationService.sendFCM(receiver.firebase_uid, {
      title: `${senderNickname}님의 새 메시지`,
      body: content,
      data: {
        type: 'private_message',
        senderId: senderFirebaseUid,
        senderNickname: senderNickname,
      },
    });

    res.status(201).json({ message: '메시지가 전송되었습니다.', message: message });
  } catch (error) {
    console.error('sendPrivateMessage 오류:', error);
    next(error);
  }
};
