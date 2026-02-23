/**
 * 게시글 모델 (posts 테이블)
 * 커뮤니티 게시글의 제목, 본문, 이미지 URL 목록, 작성자·카테고리 참조를 저장합니다.
 */

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');
const PostCategory = require('./postCategory');

const Post = sequelize.define('Post', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  authorId: {
    type: DataTypes.STRING(255),
    allowNull: false,
    references: { model: User, key: 'email' },
    onDelete: 'CASCADE',
  },
  categoryId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: PostCategory, key: 'id' },
    onDelete: 'RESTRICT', // 카테고리에 게시글이 있으면 삭제 불가
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  content: {
    type: DataTypes.TEXT('long'), // LONGTEXT (CLOB, 대용량 본문)
    allowNull: false,
  },
  imageUrls: {
    type: DataTypes.JSON, // 이미지 URL 문자열 배열
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
  tableName: 'posts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

Post.belongsTo(User, { as: 'Author', foreignKey: 'authorId' });
Post.belongsTo(PostCategory, { as: 'Category', foreignKey: 'categoryId' });
User.hasMany(Post, { foreignKey: 'authorId' });
PostCategory.hasMany(Post, { foreignKey: 'categoryId' });

module.exports = Post;
