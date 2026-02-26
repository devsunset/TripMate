/**
 * 일정 모델 (itineraries 테이블)
 * 여행 일정의 제목, 설명, 기간, 이미지 URL, 지도 데이터를 저장합니다.
 */
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');

const Itinerary = sequelize.define('Itinerary', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  authorId: {
    type: DataTypes.STRING(32),
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT('long'), // LONGTEXT (웹 에디터 본문)
    allowNull: false,
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  endDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  imageUrls: {
    type: DataTypes.JSON, // 이미지 URL 문자열 배열
    defaultValue: [],
  },
  mapData: {
    type: DataTypes.JSON, // 마커/경로용 객체 배열
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
  tableName: 'itineraries',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

Itinerary.belongsTo(User, { as: 'Author', foreignKey: 'authorId' });
User.hasMany(Itinerary, { foreignKey: 'authorId' });

module.exports = Itinerary;