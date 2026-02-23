/// 화면에 표시할 때 개인정보(아이디/이메일) 마스킹 유틸
/// 이메일인 경우: @ 앞 부분(로컬 파트)만 첫 글자·마지막 글자만 보이고 나머지는 * 처리. @ 이후는 그대로 표시.

/// [value]가 이메일이면 @ 전까지만 첫·끝 글자 제외 * 처리, 나머지 문자열이면 전체에 동일 적용.
String maskForDisplay(String? value) {
  if (value == null || value.isEmpty) return '';
  final atIndex = value.indexOf('@');
  final String localPart;
  final String suffix;
  if (atIndex >= 0) {
    localPart = value.substring(0, atIndex);
    suffix = value.substring(atIndex); // '@' 포함 뒤쪽 그대로
  } else {
    localPart = value;
    suffix = '';
  }
  if (localPart.length <= 2) return localPart + suffix;
  final mid = localPart.length - 2;
  final masked = localPart[0] + List.filled(mid, '*').join() + localPart[localPart.length - 1];
  return masked + suffix;
}
