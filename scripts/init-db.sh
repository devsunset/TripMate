#!/usr/bin/env bash
# TravelMate DB 초기화: travel_mate_backend/.env 의 DB 접속 정보로 doc/travel_mate.sql 실행
# 프로젝트 루트(TravelMate)에서 실행: bash scripts/init-db.sh
# 요구사항: MariaDB/MySQL 클라이언트(mysql) 설치 및 해당 호스트 접근 가능

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/travel_mate_backend/.env"
SQL_FILE="$ROOT_DIR/doc/travel_mate.sql"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "오류: $ENV_FILE 이 없습니다. travel_mate_backend/.env.example 을 복사해 .env 를 만든 뒤 DB 정보를 넣어주세요."
  exit 1
fi

if [[ ! -f "$SQL_FILE" ]]; then
  echo "오류: $SQL_FILE 이 없습니다."
  exit 1
fi

# .env 에서 DB_ 변수만 로드 (주석·빈 줄 제외, 따옴표 제거)
export DB_HOST="" DB_PORT="3306" DB_USER="" DB_PASSWORD="" DB_NAME=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" == DB_HOST=* ]]; then export DB_HOST="${line#DB_HOST=}"; fi
  if [[ "$line" == DB_PORT=* ]]; then export DB_PORT="${line#DB_PORT=}"; fi
  if [[ "$line" == DB_USER=* ]]; then export DB_USER="${line#DB_USER=}"; fi
  if [[ "$line" == DB_PASSWORD=* ]]; then export DB_PASSWORD="${line#DB_PASSWORD=}"; fi
  if [[ "$line" == DB_NAME=* ]]; then export DB_NAME="${line#DB_NAME=}"; fi
done < "$ENV_FILE"

# 값 앞뒤 따옴표 제거
strip_quotes() { local v="$1"; v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"; echo "$v"; }
DB_HOST="$(strip_quotes "$DB_HOST")"
DB_PORT="$(strip_quotes "$DB_PORT")"
DB_USER="$(strip_quotes "$DB_USER")"
DB_PASSWORD="$(strip_quotes "$DB_PASSWORD")"
DB_NAME="$(strip_quotes "$DB_NAME")"

if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_NAME" ]]; then
  echo "오류: .env 에 DB_HOST, DB_USER, DB_NAME 이 필요합니다."
  exit 1
fi

echo "DB 초기화: $DB_HOST:$DB_PORT (사용자: $DB_USER) — doc/travel_mate.sql 실행"
mysql -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USER" ${DB_PASSWORD:+-p"$DB_PASSWORD"} < "$SQL_FILE"
echo "완료: doc/travel_mate.sql 적용됨. (DB 생성·USE는 SQL 내부에서 수행)"
