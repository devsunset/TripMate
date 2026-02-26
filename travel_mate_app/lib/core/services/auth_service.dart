/// Firebase Auth 기반 로그인(Google만). 사용자 식별은 백엔드 랜덤 id만 사용(이메일 미수집·미저장).
/// 웹에서는 SharedPreferences, 모바일에서는 FlutterSecureStorage 사용(웹에서 secure_storage 미지원/오류 방지).
library;
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio? _dio;
  final GoogleSignIn _googleSignIn = kIsWeb && AppConstants.googleSignInWebClientId != null && AppConstants.googleSignInWebClientId!.isNotEmpty
      ? GoogleSignIn(clientId: AppConstants.googleSignInWebClientId)
      : GoogleSignIn();
  static const String _tokenKey = 'firebase_id_token';

  AuthService({Dio? dio}) : _dio = dio;

  /// 인증 상태 스트림(로그인/로그아웃 시 갱신).
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  /// Firebase 유저가 있어도 백엔드 GET /api/auth/me 로 유효성 검사. 401 등 실패 시 로그아웃 후 null 방출.
  /// 라우터는 이 스트림을 사용해 로그인 여부를 판단하면, 토큰 만료 시 로그인 화면으로 보낼 수 있음.
  Stream<User?> get verifiedUser async* {
    await for (final user in _firebaseAuth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        final userId = await getCurrentBackendUserId();
        if (userId == null) {
          await signOut();
          yield null;
        } else {
          yield user;
        }
      }
    }
  }

  /// 토큰 저장(실패해도 예외 전파하지 않음 — 로그인 성공을 깨지 않도록).
  Future<void> _storeIdToken(String? token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        } else {
          await prefs.remove(_tokenKey);
        }
      } else {
        const storage = FlutterSecureStorage();
        if (token != null) {
          await storage.write(key: _tokenKey, value: token);
        } else {
          await storage.delete(key: _tokenKey);
        }
      }
    } catch (e) {
      developer.log('Token storage failed (non-fatal): $e', name: 'Auth', level: 1000);
    }
  }

  /// 저장된 Firebase ID 토큰 조회. 없으면 Firebase 현재 유저에서 갱신 시도.
  Future<String?> getIdToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(_tokenKey);
        if (stored != null && stored.isNotEmpty) return stored;
      } else {
        const storage = FlutterSecureStorage();
        final stored = await storage.read(key: _tokenKey);
        if (stored != null && stored.isNotEmpty) return stored;
      }
      final token = await _firebaseAuth.currentUser?.getIdToken();
      if (token != null) await _storeIdToken(token);
      return token;
    } catch (e) {
      developer.log('getIdToken failed: $e', name: 'Auth', level: 1000);
      return _firebaseAuth.currentUser?.getIdToken();
    }
  }

  /// Google 로그인. 취소 또는 실패 시 null. (이메일·비밀번호 로그인 미지원)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      await _storeIdToken(await result.user?.getIdToken());
      return result.user;
    } catch (e) {
      developer.log(e.toString(), name: 'Auth', level: 1000);
      await _storeIdToken(null);
      return null;
    }
  }

  /// 로그아웃. Firebase·Google 로그아웃 및 저장된 토큰 삭제.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _storeIdToken(null);
    } catch (e) {
      developer.log(e.toString(), name: 'Auth', level: 1000);
    }
  }

  /// 백엔드 사용자 ID 조회. GET /api/auth/me 호출. 토큰 없거나 실패 시 null.
  /// 공유 Dio에 baseUrl이 없을 수 있으므로 항상 전체 URL로 요청합니다.
  Future<String?> getCurrentBackendUserId() async {
    try {
      final token = await getIdToken();
      if (token == null || token.isEmpty) return null;
      final url = '${AppConstants.apiBaseUrl}/api/auth/me';
      final dio = _dio ?? Dio();
      final response = await dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ),
      );
      final userId = response.data?['userId'];
      return userId is String ? userId : userId?.toString();
    } catch (e) {
      developer.log('getCurrentBackendUserId failed: $e', name: 'Auth', level: 1000);
      return null;
    }
  }
}
