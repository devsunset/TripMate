/**
 * TravelMate DB 초기화
 * travel_mate_backend/.env 의 DB 접속 정보로 doc/travel_mate.sql 전체 실행
 * 실행: travel_mate_backend 폴더에서 node scripts/init-db.js
 */
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const mariadb = require('mariadb');

const backendRoot = path.resolve(__dirname, '..');
const envPath = path.join(backendRoot, '.env');
const sqlPath = path.resolve(backendRoot, '..', 'doc', 'travel_mate.sql');

dotenv.config({ path: envPath });

const config = {
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD || '',
  // SQL 파일에 CREATE DATABASE + USE 가 있으므로 연결 시 DB 미지정
};

async function main() {
  if (!config.host || !config.user) {
    console.error('오류: .env에 DB_HOST, DB_USER가 필요합니다.');
    process.exit(1);
  }
  if (!fs.existsSync(sqlPath)) {
    console.error('오류: SQL 파일이 없습니다.', sqlPath);
    process.exit(1);
  }

  const sql = fs.readFileSync(sqlPath, 'utf8');
  const conn = await mariadb.createConnection({
    ...config,
    multipleStatements: true,
  });

  try {
    console.log('DB 초기화:', config.host + ':' + config.port, '/', config.database);
    await conn.query(sql);
    console.log('완료: doc/travel_mate.sql 적용됨.');
  } finally {
    await conn.end();
  }
}

main().catch((err) => {
  console.error('DB 초기화 실패:', err.message);
  process.exit(1);
});
