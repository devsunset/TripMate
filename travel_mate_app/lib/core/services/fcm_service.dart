/// FCM 권한 요청, 토큰 발급/갱신, 백엔드에 토큰 전송, 포그라운드/백그라운드 메시지 수신 처리.
library;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:logger/logger.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;
  final Logger _logger = Logger();

  FcmService({FirebaseMessaging? firebaseMessaging, FirebaseAuth? firebaseAuth, Dio? dio})
      : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dio = dio ?? Dio();

  /// 알림 권한 요청, FCM 토큰 획득·갱신, 백엔드 전송, 포그라운드/백그라운드 메시지 리스너 등록.
  /// 로그인 상태 변경 시에도 토큰을 백엔드에 전송(Google 로그인 등).
  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('FCM: 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      _logger.i('FCM: 임시 알림 권한 허용됨');
    } else {
      _logger.w('FCM: 알림 권한 거부 또는 미응답');
      return;
    }

    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _sendFcmTokenToBackend(token);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _logger.i('FCM 토큰 갱신됨: $newToken');
      await _sendFcmTokenToBackend(newToken);
    });

    _firebaseAuth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final t = await _firebaseMessaging.getToken();
        if (t != null) await _sendFcmTokenToBackend(t);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('FCM: 포그라운드 메시지 수신: ${message.data}');
      if (message.notification != null) {
        _logger.i('FCM: 알림: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('FCM: 알림 탭으로 앱 열림: ${message.data}');
    });
  }

  /// FCM 토큰을 백엔드 /api/fcm/token 에 전송.
  Future<void> _sendFcmTokenToBackend(String token) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _logger.w('FCM: 로그인되지 않아 토큰 전송 생략.');
      return;
    }

    try {
      final idToken = await currentUser.getIdToken();
      if (idToken == null) {
        throw Exception('Firebase ID 토큰이 없습니다.');
      }

      String deviceType = 'unknown';
      if (kIsWeb) {
        deviceType = 'web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        deviceType = 'android';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        deviceType = 'ios';
      }

      await _dio.post(
        '${AppConstants.apiBaseUrl}/api/fcm/token',
        data: {
          'token': token,
          'deviceType': deviceType,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );
      _logger.i('FCM 토큰 백엔드 전송 완료.');
    } on DioException catch (e) {
      _logger.e('FCM 토큰 전송 실패: ${e.response?.data ?? e.message}', error: e);
    } catch (e) {
      _logger.e('FCM 토큰 전송 오류: $e', error: e);
    }
  }
}