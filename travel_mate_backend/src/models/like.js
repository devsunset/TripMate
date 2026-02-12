/**
 * 좋아요 모델 (likes 테이블)
 * 게시글 또는 일정에 대한 사용자별 좋아요를 저장합니다.
 * (userId, postId) 또는 (userId, itineraryId) 조합은 유일합니다.
 */

const { DataTypes, Op } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');
const Post = require('./post');
const Itinerary = require('./itinerary');

const Like = sequelize.define('Like', {
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: { model: User, key: 'id' },
    onDelete: 'CASCADE',
  },
  postId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    primaryKey: true,
    references: { model: Post, key: 'id' },
    onDelete: 'CASCADE',
  },
  itineraryId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    primaryKey: true,
    references: { model: Itinerary, key: 'id' },
    onDelete: 'CASCADE',
  },
  created_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'likes',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
  indexes: [
    { unique: true, fields: ['userId', 'postId'], where: { postId: { [Op.ne]: null } } },
    { unique: true, fields: ['userId', 'itineraryId'], where: { itineraryId: { [Op.ne]: null } } },
  ],
});

Like.belongsTo(User, { foreignKey: 'userId' });
Like.belongsTo(Post, { foreignKey: 'postId' });
Like.belongsTo(Itinerary, { foreignKey: 'itineraryId' });
Post.hasMany(Like, { foreignKey: 'postId', as: 'Likes' });
Itinerary.hasMany(Like, { foreignKey: 'itineraryId', as: 'Likes' });

module.exports = Like;
