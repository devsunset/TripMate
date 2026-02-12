/**
 * 사용자 프로필-태그 N:M 매핑 모델 (user_profile_tags 테이블)
 * 프로필에 붙은 태그를 저장하며, 동일 (userProfileId, tagId) 조합은 한 번만 허용합니다.
 */

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const UserProfile = require('./userProfile');
const Tag = require('./tag');

const UserProfileTag = sequelize.define('UserProfileTag', {
  userProfileId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: { model: UserProfile, key: 'id' },
    onDelete: 'CASCADE',
  },
  tagId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: { model: Tag, key: 'id' },
    onDelete: 'CASCADE',
  },
  created_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'user_profile_tags',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
  indexes: [{ unique: true, fields: ['userProfileId', 'tagId'] }],
});

UserProfile.belongsToMany(Tag, { through: UserProfileTag, foreignKey: 'userProfileId' });
Tag.belongsToMany(UserProfile, { through: UserProfileTag, foreignKey: 'tagId' });

module.exports = UserProfileTag;
