/**
 * 사용자 프로필 모델 (user_profiles 테이블)
 * 닉네임, 소개, 프로필 이미지, 성별/연령대, 여행 스타일·관심사·선호지역 등을 저장합니다.
 * 사용자당 하나의 프로필만 가집니다.
 */

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');

const UserProfile = sequelize.define('UserProfile', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.STRING(32),
    allowNull: false,
    unique: true,
    references: { model: User, key: 'id' },
    onDelete: 'CASCADE',
  },
  nickname: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  bio: {
    type: DataTypes.TEXT,
  },
  profileImageUrl: {
    type: DataTypes.STRING,
  },
  gender: {
    type: DataTypes.STRING, // 예: 'Male', 'Female', 'Other'
  },
  ageRange: {
    type: DataTypes.STRING, // 예: '20s', '30s', '40s+'
  },
  travelStyles: {
    type: DataTypes.JSON, // 문자열 배열 (JSON)
    defaultValue: [],
  },
  interests: {
    type: DataTypes.JSON,
    defaultValue: [],
  },
  preferredDestinations: {
    type: DataTypes.JSON,
    defaultValue: [],
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
  tableName: 'user_profiles',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // 인덱스는 doc/travel_mate.sql의 idx_gender_ageRange로 생성. sync() 시 ADD INDEX가 기존 CHECK(JSON)와 충돌해 에러나므로 여기서는 정의하지 않음.
});

User.hasOne(UserProfile, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserProfile.belongsTo(User, { foreignKey: 'userId' });

module.exports = UserProfile;
