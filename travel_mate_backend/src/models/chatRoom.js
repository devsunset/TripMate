/**
 * 채팅방 모델 (chat_rooms 테이블)
 * Firestore 채팅방 ID와 두 사용자, 마지막 메시지 요약을 저장합니다.
 * user1Id·user2Id 쌍은 순서와 관계없이 유일해야 하며, 인덱스로 보장합니다.
 */

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');

const ChatRoom = sequelize.define('ChatRoom', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  firestoreChatId: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true, // Firestore에서 사용하는 채팅방 ID (예: 'user1Id_user2Id')
  },
  user1Id: {
    type: DataTypes.STRING(255),
    allowNull: false,
    references: { model: User, key: 'email' },
    onDelete: 'CASCADE',
  },
  user2Id: {
    type: DataTypes.STRING(255),
    allowNull: false,
    references: { model: User, key: 'email' },
    onDelete: 'CASCADE',
  },
  createdByUserId: {
    type: DataTypes.STRING(255),
    allowNull: true,
    references: { model: User, key: 'email' },
    onDelete: 'SET NULL',
    comment: '채팅을 신청한 사용자 이메일',
  },
  lastMessage: {
    type: DataTypes.TEXT,
  },
  lastMessageSentAt: {
    type: DataTypes.DATE,
  },
  created_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  updated_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'chat_rooms',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { unique: true, fields: ['user1Id', 'user2Id'] },
    { unique: true, fields: ['user2Id', 'user1Id'] },
  ],
});

ChatRoom.belongsTo(User, { as: 'User1', foreignKey: 'user1Id' });
ChatRoom.belongsTo(User, { as: 'User2', foreignKey: 'user2Id' });

module.exports = ChatRoom;
