/**
 * 신고 모델 (reports 테이블)
 * 사용자·게시글·일정·댓글에 대한 신고 내역을 저장합니다.
 */
const { DataTypes, Op } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');
const Post = require('./post');
const Itinerary = require('./itinerary');
const Comment = require('./comment');

const Report = sequelize.define('Report', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  reporterUserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  reportedUserId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: User,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  reportedPostId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: Post,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  reportedItineraryId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: Itinerary,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  reportedCommentId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: Comment,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  reportType: {
    type: DataTypes.STRING, // e.g., 'Spam', 'Hate Speech', 'Harassment', 'Other'
    allowNull: false,
  },
  reason: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  status: {
    type: DataTypes.STRING, // e.g., 'pending', 'resolved', 'rejected'
    defaultValue: 'pending',
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
  tableName: 'reports',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      unique: true,
      fields: ['reporterUserId', 'reportedUserId'],
      where: { reportedUserId: { [Op.ne]: null } }
    },
    {
      unique: true,
      fields: ['reporterUserId', 'reportedPostId'],
      where: { reportedPostId: { [Op.ne]: null } }
    },
    {
      unique: true,
      fields: ['reporterUserId', 'reportedItineraryId'],
      where: { reportedItineraryId: { [Op.ne]: null } }
    },
    {
      unique: true,
      fields: ['reporterUserId', 'reportedCommentId'],
      where: { reportedCommentId: { [Op.ne]: null } }
    },
  ]
});

// Associations
Report.belongsTo(User, { as: 'Reporter', foreignKey: 'reporterUserId' });
Report.belongsTo(User, { as: 'ReportedUser', foreignKey: 'reportedUserId' });
Report.belongsTo(Post, { as: 'ReportedPost', foreignKey: 'reportedPostId' });
Report.belongsTo(Itinerary, { as: 'ReportedItinerary', foreignKey: 'reportedItineraryId' });
Report.belongsTo(Comment, { as: 'ReportedComment', foreignKey: 'reportedCommentId' });

module.exports = Report;