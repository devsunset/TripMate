/**
 * DB 컬럼 자료형 길이에 맞춘 입력값 검증/제한
 * 자료형보다 큰 값이 입력되지 않도록 컨트롤러에서 사용합니다.
 */

/** DB 컬럼 최대 길이 상수 (VARCHAR/문자열 필드) */
const LIMITS = {
  // users
  email: 255,
  firebase_uid: 255,

  // user_profiles
  nickname: 255,
  bio: 65535, // TEXT
  profileImageUrl: 512,
  gender: 50,
  ageRange: 50,

  // posts
  postTitle: 255,
  postContent: 4 * 1024 * 1024, // LONGTEXT ~4MB, API에서 상한 적용

  // comments
  commentContent: 65535, // TEXT

  // itineraries
  itineraryTitle: 255,
  itineraryDescription: 65535, // TEXT

  // itinerary_activities
  activityTime: 255,
  activityDescription: 65535,
  activityLocation: 255,

  // chat_rooms
  firestoreChatId: 255,

  // private_messages
  messageContent: 65535, // TEXT

  // fcm_tokens
  fcmToken: 255,
  deviceType: 50,

  // reports
  reportType: 255,
  reportReason: 65535,
  reportStatus: 50,
};

/**
 * 문자열이 최대 길이를 초과하면 에러 메시지 반환, 아니면 null
 * @param {string} value - 검사할 값
 * @param {number} maxLen - 최대 길이
 * @param {string} fieldName - 에러 메시지용 필드명
 * @returns {string|null} 에러 메시지 또는 null
 */
function checkMaxLength(value, maxLen, fieldName = '필드') {
  if (value == null) return null;
  const str = String(value);
  if (str.length > maxLen) {
    return `${fieldName}은(는) ${maxLen}자를 초과할 수 없습니다. (현재 ${str.length}자)`;
  }
  return null;
}

/**
 * 여러 필드에 대해 길이 검사. 첫 번째 오류 메시지 반환
 * @param {Object} pairs - { fieldName: { value, maxLen, label? } } 또는 [ [value, maxLen, label], ... ]
 * @returns {{ ok: boolean, message?: string }}
 */
function validateLengths(pairs) {
  const entries = Array.isArray(pairs)
    ? pairs
    : Object.entries(pairs).map(([k, v]) => [v.value != null ? v.value : v, v.maxLen, v.label || k]);
  for (const [value, maxLen, label] of entries) {
    const msg = checkMaxLength(value, maxLen, label);
    if (msg) return { ok: false, message: msg };
  }
  return { ok: true };
}

/**
 * 문자열을 최대 길이로 자른 값 반환 (DB 저장용 트림)
 * @param {string} value
 * @param {number} maxLen
 * @returns {string}
 */
function trimToMax(value, maxLen) {
  if (value == null) return '';
  const str = String(value).trim();
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen);
}

module.exports = {
  LIMITS,
  checkMaxLength,
  validateLengths,
  trimToMax,
};
