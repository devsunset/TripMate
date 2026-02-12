/// Firebase Auth 기반 로그인(이메일/비밀번호, Google), ID 토큰 로컬 저장.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_mate_app/app/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = kIsWeb && AppConstants.googleSignInWebClientId != null
      ? GoogleSignIn(clientId: AppConstants.googleSignInWebClientId)
      : GoogleSignIn();

  /// 인증 상태 스트림(로그인/로그아웃 시 갱신).
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  /// Firebase ID 토큰을 SharedPreferences에 저장 또는 삭제.
  Future<void> _storeIdToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('firebase_id_token', token);
    } else {
      await prefs.remove('firebase_id_token');
    }
  }

  /// SharedPreferences에 저장된 Firebase ID 토큰 조회.
  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_id_token');
  }

  /// 이메일·비밀번호 로그인. 실패 시 null.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      await _storeIdToken(await result.user?.getIdToken());
      return result.user;
    } catch (e) {
      print(e.toString());
      await _storeIdToken(null);
      return null;
    }
  }

  /// 이메일·비밀번호로 회원가입 후 토큰 저장.
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _storeIdToken(await result.user?.getIdToken());
      return result.user;
    } catch (e) {
      print(e.toString());
      await _storeIdToken(null);
      return null;
    }
  }

  /// Google 로그인. 취소 또는 실패 시 null.
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
      print(e.toString());
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
      print(e.toString());
      return null;
    }
  }
}
