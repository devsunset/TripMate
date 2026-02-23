/**
 * 채팅방 컨트롤러
 * 채팅 요청(방 생성) 및 내가 참여한 채팅방 목록(신청한/신청받은) 조회.
 * firestoreChatId는 이메일 정렬 후 조합.
 */
const { Op } = require('sequelize');
const sequelize = require('../config/database');
const ChatRoom = require('../models/chatRoom');
const User = require('../models/user');
const UserProfile = require('../models/userProfile');

/** 채팅 요청(방 생성): partnerId는 상대 이메일. 방이 없으면 생성(createdByUserId=현재 사용자), 있으면 기존 반환 */
exports.createChatRoom = async (req, res, next) => {
  try {
    const { partnerId: partnerEmail } = req.body;
    const currentFirebaseUid = req.user.uid;
    if (!partnerEmail) {
      return res.status(400).json({ message: '채팅 상대 ID(이메일)가 필요합니다.' });
    }
    const currentUser = await User.findOne({ where: { firebase_uid: currentFirebaseUid } });
    const partnerUser = await User.findOne({ where: { email: partnerEmail } });
    if (!currentUser || !partnerUser) {
      return res.status(404).json({ message: '사용자 또는 상대를 찾을 수 없습니다.' });
    }
    const firestoreChatId = [currentUser.email, partnerUser.email].sort().join('_');
    const user1Email = currentUser.email < partnerUser.email ? currentUser.email : partnerUser.email;
    const user2Email = currentUser.email < partnerUser.email ? partnerUser.email : currentUser.email;
    let chatRoom = await ChatRoom.findOne({
      where: {
        [Op.or]: [
          { user1Id: user1Email, user2Id: user2Email },
          { user1Id: user2Email, user2Id: user1Email },
        ],
      },
    });

    if (chatRoom) {
      return res.status(200).json({
        message: '채팅방이 이미 존재합니다.',
        chatRoomId: chatRoom.firestoreChatId,
        isRequestedByMe: chatRoom.createdByUserId === currentUser.email,
      });
    }

    chatRoom = await ChatRoom.create({
      firestoreChatId,
      user1Id: user1Email,
      user2Id: user2Email,
      createdByUserId: currentUser.email,
    });

    res.status(201).json({
      message: '채팅 요청이 완료되었습니다. 채팅 목록에서 선택해 대화하세요.',
      chatRoomId: chatRoom.firestoreChatId,
      isRequestedByMe: true,
    });
  } catch (error) {
    console.error('createChatRoom 오류:', error);
    next(error);
  }
};

/** 내가 참여한 채팅방 목록: 신청한 채팅(createdByUserId=나) + 신청받은 채팅. 정렬: 최근 메시지/생성일 */
exports.getMyChatRooms = async (req, res, next) => {
  try {
    const currentFirebaseUid = req.user.uid;
    const currentUser = await User.findOne({ where: { firebase_uid: currentFirebaseUid } });
    if (!currentUser) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }
    const myEmail = currentUser.email;

    const rooms = await ChatRoom.findAll({
      where: {
        [Op.or]: [
          { user1Id: myEmail },
          { user2Id: myEmail },
        ],
      },
      include: [
        { model: User, as: 'User1', attributes: ['email'], include: [{ model: UserProfile, attributes: ['nickname', 'profileImageUrl'] }] },
        { model: User, as: 'User2', attributes: ['email'], include: [{ model: UserProfile, attributes: ['nickname', 'profileImageUrl'] }] },
      ],
      order: [[sequelize.literal('COALESCE(lastMessageSentAt, created_at)'), 'DESC']],
    });

    const list = rooms.map((r) => {
      const partner = r.user1Id === myEmail ? r.User2 : r.User1;
      const partnerEmail = partner?.email ?? (r.user1Id === myEmail ? r.user2Id : r.user1Id);
      const partnerProfile = partner?.UserProfile;
      const nickname = partnerProfile?.nickname ?? partnerEmail;
      return {
        chatRoomId: r.firestoreChatId,
        partnerEmail,
        partnerNickname: nickname,
        partnerProfileImageUrl: partnerProfile?.profileImageUrl ?? null,
        lastMessage: r.lastMessage ?? '',
        lastMessageAt: r.lastMessageSentAt ? r.lastMessageSentAt.toISOString() : r.created_at.toISOString(),
        isRequestedByMe: r.createdByUserId === myEmail,
      };
    });

    res.status(200).json({ chatRooms: list });
  } catch (error) {
    console.error('getMyChatRooms 오류:', error);
    next(error);
  }
};
