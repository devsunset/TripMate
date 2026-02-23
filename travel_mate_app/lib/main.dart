/// TravelMate 앱 진입점.
/// Firebase 초기화, FCM 백그라운드 핸들러 등록, Provider 의존성 주입 후 [TravelMateApp] 실행.
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:travel_mate_app/firebase_options.dart';
import 'package:travel_mate_app/app/app.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/core/services/fcm_service.dart';
import 'package:travel_mate_app/data/datasources/profile_remote_datasource.dart';
import 'package:travel_mate_app/data/datasources/message_remote_datasource.dart';
import 'package:travel_mate_app/data/datasources/chat_remote_datasource.dart';
import 'package:travel_mate_app/data/datasources/chat_api_datasource.dart';
import 'package:travel_mate_app/data/datasources/post_remote_datasource.dart';
import 'package:travel_mate_app/data/datasources/itinerary_remote_datasource.dart';
import 'package:travel_mate_app/data/repositories/user_profile_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/tag_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/message_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/chat_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/post_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/itinerary_repository_impl.dart';
import 'package:travel_mate_app/data/repositories/companion_repository_impl.dart';
import 'package:travel_mate_app/data/datasources/companion_search_remote_datasource.dart';
import 'package:travel_mate_app/domain/repositories/user_profile_repository.dart';
import 'package:travel_mate_app/domain/repositories/companion_repository.dart';
import 'package:travel_mate_app/domain/repositories/tag_repository.dart';
import 'package:travel_mate_app/domain/repositories/message_repository.dart';
import 'package:travel_mate_app/domain/repositories/chat_repository.dart';
import 'package:travel_mate_app/domain/repositories/post_repository.dart';
import 'package:travel_mate_app/domain/repositories/itinerary_repository.dart';
import 'package:travel_mate_app/domain/usecases/get_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/create_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/update_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/upload_profile_image.dart';
import 'package:travel_mate_app/domain/usecases/get_tags.dart';
import 'package:travel_mate_app/domain/usecases/send_private_message.dart';
import 'package:travel_mate_app/domain/usecases/get_chat_messages.dart';
import 'package:travel_mate_app/domain/usecases/get_chat_rooms.dart';
import 'package:travel_mate_app/domain/usecases/create_chat_room.dart';
import 'package:travel_mate_app/domain/usecases/send_chat_message.dart';
import 'package:travel_mate_app/domain/usecases/get_posts.dart';
import 'package:travel_mate_app/domain/usecases/get_post.dart';
import 'package:travel_mate_app/domain/usecases/create_post.dart';
import 'package:travel_mate_app/domain/usecases/update_post.dart';
import 'package:travel_mate_app/domain/usecases/delete_post.dart';
import 'package:travel_mate_app/domain/usecases/upload_post_image.dart';
import 'package:travel_mate_app/domain/usecases/get_itineraries.dart';
import 'package:travel_mate_app/domain/usecases/get_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/create_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/update_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/delete_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/upload_itinerary_image.dart';
import 'package:travel_mate_app/domain/usecases/search_companions_usecase.dart';

/// 앱 진입점: Firebase 초기화 후 FCM 백그라운드 핸들러 등록, Provider 트리 구성 후 runApp.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --dart-define을 통해 전달된 환경 변수 설정
  const String apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
  const String googleClientIdEnv = String.fromEnvironment('GOOGLE_SIGN_IN_WEB_CLIENT_ID', defaultValue: '');

  AppConstants.setApiBaseUrl(apiUrl);
  // env에 값이 있을 때만 덮어씀. 비어 있으면 constants.dart 기본 Web Client ID 유지(웹 Google 로그인용).
  if (googleClientIdEnv.isNotEmpty) {
    AppConstants.setGoogleSignInWebClientId(googleClientIdEnv);
  }

  // 에러 발생 시 콘솔에 error 레벨로 로그 출력. 화면에는 간단 안내만 표시.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError: ${details.exceptionAsString()}\n${details.stack?.toString() ?? ''}',
      name: 'FlutterError',
      level: 1000,
    );
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    developer.log(
      'ErrorWidget: ${details.exceptionAsString()}\n${details.stack?.toString() ?? ''}',
      name: 'ErrorWidget',
      level: 1000,
    );
    return Material(
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('오류가 발생했습니다.\n콘솔(개발자 도구)에서 상세 로그를 확인하세요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SelectableText(details.exceptionAsString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        // Core Services Providers
        Provider<Dio>(create: (_) => Dio()),
        Provider<FirebaseMessaging>(create: (_) => FirebaseMessaging.instance),
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        Provider<FcmService>(
          create: (context) => FcmService(
            firebaseMessaging: context.read<FirebaseMessaging>(),
            firebaseAuth: FirebaseAuth.instance,
            dio: context.read<Dio>(),
          ),
        ),

        // Remote Data Source Providers
        Provider<ProfileRemoteDataSource>(create: (context) => ProfileRemoteDataSource(dio: context.read<Dio>())),
        Provider<MessageRemoteDataSource>(create: (context) => MessageRemoteDataSource(dio: context.read<Dio>())),
        Provider<ChatRemoteDataSource>(
          create: (context) => ChatRemoteDataSource(
            firestore: context.read<FirebaseFirestore>(),
            firebaseAuth: FirebaseAuth.instance,
          ),
        ),
        Provider<ChatApiDataSource>(
          create: (context) => ChatApiDataSource(
            firebaseAuth: FirebaseAuth.instance,
            dio: context.read<Dio>(),
          ),
        ),
        Provider<PostRemoteDataSource>(create: (context) => PostRemoteDataSource(dio: context.read<Dio>())),
        Provider<ItineraryRemoteDataSource>(create: (context) => ItineraryRemoteDataSource(dio: context.read<Dio>())),
        Provider<CompanionSearchRemoteDataSource>(
          create: (context) => CompanionSearchRemoteDataSource(dio: context.read<Dio>()),
        ),

        // Repository Providers
        Provider<UserProfileRepository>(
          create: (context) => UserProfileRepositoryImpl(remoteDataSource: context.read<ProfileRemoteDataSource>()),
        ),
        Provider<TagRepository>(create: (_) => TagRepositoryImpl()),
        Provider<MessageRepository>(
          create: (context) => MessageRepositoryImpl(remoteDataSource: context.read<MessageRemoteDataSource>()),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepositoryImpl(
            remoteDataSource: context.read<ChatRemoteDataSource>(),
            apiDataSource: context.read<ChatApiDataSource>(),
          ),
        ),
        Provider<PostRepository>(
          create: (context) => PostRepositoryImpl(remoteDataSource: context.read<PostRemoteDataSource>()),
        ),
        Provider<ItineraryRepository>(
          create: (context) => ItineraryRepositoryImpl(remoteDataSource: context.read<ItineraryRemoteDataSource>()),
        ),
        Provider<CompanionRepository>(
          create: (context) => CompanionRepositoryImpl(remoteDataSource: context.read<CompanionSearchRemoteDataSource>()),
        ),

        // UseCase Providers
        Provider<GetUserProfile>(create: (context) => GetUserProfile(context.read<UserProfileRepository>())),
        Provider<CreateUserProfile>(create: (context) => CreateUserProfile(context.read<UserProfileRepository>())),
        Provider<UpdateUserProfile>(create: (context) => UpdateUserProfile(context.read<UserProfileRepository>())),
        Provider<UploadProfileImage>(create: (context) => UploadProfileImage(context.read<UserProfileRepository>())),
        Provider<GetTags>(create: (context) => GetTags(context.read<TagRepository>())),
        Provider<SendPrivateMessage>(create: (context) => SendPrivateMessage(context.read<MessageRepository>())),
        Provider<GetChatMessages>(create: (context) => GetChatMessages(context.read<ChatRepository>())),
        Provider<GetChatRooms>(create: (context) => GetChatRooms(context.read<ChatRepository>())),
        Provider<CreateChatRoom>(create: (context) => CreateChatRoom(context.read<ChatRepository>())),
        Provider<SendChatMessage>(create: (context) => SendChatMessage(context.read<ChatRepository>())),
        Provider<GetPosts>(create: (context) => GetPosts(context.read<PostRepository>())),
        Provider<GetPost>(create: (context) => GetPost(context.read<PostRepository>())),
        Provider<CreatePost>(create: (context) => CreatePost(context.read<PostRepository>())),
        Provider<UpdatePost>(create: (context) => UpdatePost(context.read<PostRepository>())),
        Provider<DeletePost>(create: (context) => DeletePost(context.read<PostRepository>())),
        Provider<UploadPostImage>(create: (context) => UploadPostImage(context.read<PostRepository>())),
        Provider<GetItineraries>(create: (context) => GetItineraries(context.read<ItineraryRepository>())),
        Provider<GetItinerary>(create: (context) => GetItinerary(context.read<ItineraryRepository>())),
        Provider<CreateItinerary>(create: (context) => CreateItinerary(context.read<ItineraryRepository>())),
        Provider<UpdateItinerary>(create: (context) => UpdateItinerary(context.read<ItineraryRepository>())),
        Provider<DeleteItinerary>(create: (context) => DeleteItinerary(context.read<ItineraryRepository>())),
        Provider<UploadItineraryImage>(create: (context) => UploadItineraryImage(context.read<ItineraryRepository>())),
        Provider<SearchCompanionsUsecase>(create: (context) => SearchCompanionsUsecase(context.read<CompanionRepository>())),
      ],
      child: const FCMInitializer(child: TravelMateApp()),
    ),
  );
}

/// FCM 백그라운드 수신 핸들러. 백그라운드에서 알림 수신 시 호출됨.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("백그라운드 메시지 처리: ${message.messageId}");
}

/// 앱 빌드 후 FCM 초기화를 수행하는 래퍼 위젯.
class FCMInitializer extends StatefulWidget {
  final Widget child;
  const FCMInitializer({Key? key, required this.child}) : super(key: key);

  @override
  State<FCMInitializer> createState() => _FCMInitializerState();
}

class _FCMInitializerState extends State<FCMInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  /// Provider 준비 후 FCM 서비스 초기화(토큰 갱신 등).
  Future<void> _initializeFCM() async {
    await Future.delayed(Duration.zero);
    try {
      final fcmService = Provider.of<FcmService>(context, listen: false);
      await fcmService.initialize();
      print('FCM 서비스 초기화 완료.');
    } catch (e) {
      developer.log('FCM 서비스 초기화 오류: $e', name: 'FCM', level: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
