/**
 * MariaDB 데이터베이스 연결 설정
 * Sequelize 인스턴스를 생성하고 연결 풀을 구성합니다.
 */

const fs = require('fs');
const path = require('path');
const { Sequelize } = require('sequelize');
const dotenv = require('dotenv');

// .env 파일에서 환경 변수 로드 (travel_mate_backend 루트 기준)
const envFile = process.env.NODE_ENV ? `.env.${process.env.NODE_ENV}` : '.env';
const envPath = path.resolve(__dirname, '../../', envFile);
dotenv.config({ path: envPath });

// 기본 .env 파일도 로드하여 환경별 파일에 없는 변수는 기본값 사용
const defaultEnvPath = path.resolve(__dirname, '../../.env');
if (fs.existsSync(defaultEnvPath)) {
  dotenv.config({ path: defaultEnvPath, override: true });
}

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'mariadb',
    logging: false, // true로 설정 시 콘솔에 SQL 쿼리 출력
    pool: {
      max: 5,   // 풀 내 최대 연결 수
      min: 0,   // 풀 내 최소 연결 수
      acquire: 30000, // 연결 획득 대기 최대 시간(ms)
      idle: 10000,    // 유휴 연결 유지 최대 시간(ms) 후 반환
    },
  }
);

/**
 * 데이터베이스 연결 테스트
 * 앱 기동 시 한 번 호출되어 연결 가능 여부를 확인합니다.
 */
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('데이터베이스 연결에 성공했습니다.');
  } catch (error) {
    console.error('데이터베이스 연결 실패:', error);
  }
}

testConnection();

module.exports = sequelize;
