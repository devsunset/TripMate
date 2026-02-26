/// GoRouter 설정. 로그인 여부에 따라 보호 경로 리다이렉트, 홈/로그인/프로필/채팅/커뮤니티/신고 등 경로 정의.
/// 사용자 식별은 백엔드 랜덤 id만 사용(이메일 미수집·미저장).
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/presentation/auth/login_screen.dart';
import 'package:travel_mate_app/presentation/auth/signup_screen.dart';
import 'package:travel_mate_app/presentation/profile/profile_edit_screen.dart';
import 'package:travel_mate_app/presentation/settings/account_settings_screen.dart';
import 'package:travel_mate_app/presentation/matching/companion_search_screen.dart';
import 'package:travel_mate_app/presentation/profile/user_profile_screen.dart';
import 'package:travel_mate_app/presentation/chat/chat_list_screen.dart';
import 'package:travel_mate_app/presentation/chat/chat_room_screen.dart';
import 'package:travel_mate_app/presentation/community/community_screen.dart';
import 'package:travel_mate_app/presentation/community/post_detail_screen.dart';
import 'package:travel_mate_app/presentation/community/post_write_screen.dart';
import 'package:travel_mate_app/presentation/common/report_submission_screen.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart';
import 'package:travel_mate_app/presentation/itinerary/itinerary_list_screen.dart';
import 'package:travel_mate_app/presentation/itinerary/itinerary_detail_screen.dart';
import 'package:travel_mate_app/presentation/itinerary/itinerary_write_screen.dart';
import 'package:travel_mate_app/presentation/home/home_screen.dart';





final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(User? user) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) {
          return const SignupScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const _ProfileRedirectScreen();
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileEditScreen();
        },
      ),
      GoRoute(
        path: '/settings/account',
        builder: (BuildContext context, GoRouterState state) {
          return const AccountSettingsScreen();
        },
      ),
      GoRoute(
        path: '/matching/search',
        builder: (BuildContext context, GoRouterState state) {
          return const CompanionSearchScreen();
        },
      ),
      GoRoute(
        path: '/users/:userId',
        builder: (BuildContext context, GoRouterState state) {
          final raw = state.pathParameters['userId'] ?? '';
          final userId = raw.isNotEmpty ? Uri.decodeComponent(raw) : '';
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (BuildContext context, GoRouterState state) {
          return const ChatListScreen();
        },
      ),
      GoRoute(
        path: '/chat/room/:chatRoomId',
        builder: (BuildContext context, GoRouterState state) {
          final raw = state.pathParameters['chatRoomId'] ?? '';
          final chatRoomId = raw.isNotEmpty ? Uri.decodeComponent(raw) : raw;
          final extra = state.extra;
          final receiverNickname = extra is String ? extra : null;
          return ChatRoomScreen(chatRoomId: chatRoomId, receiverNickname: receiverNickname);
        },
      ),
      GoRoute(
        path: '/community',
        builder: (BuildContext context, GoRouterState state) {
          return const CommunityScreen();
        },
      ),
      GoRoute(
        path: '/community/post/new',
        builder: (BuildContext context, GoRouterState state) {
          return const PostWriteScreen();
        },
      ),
      GoRoute(
        path: '/community/post/:postId',
        builder: (BuildContext context, GoRouterState state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/community/post/:postId/edit',
        builder: (BuildContext context, GoRouterState state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostWriteScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/report',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const _RedirectToHome();
          }
          final args = extra;
          final entityType = args['entityType'];
          final entityId = args['entityId'];
          final reporterUserId = args['reporterUserId'];
          if (entityType is! ReportEntityType || entityId is! String || reporterUserId is! String) {
            return const _RedirectToHome();
          }
          return ReportSubmissionScreen(
            entityType: entityType,
            entityId: entityId,
            reporterUserId: reporterUserId,
          );
        },
      ),
      GoRoute(
        path: '/itinerary',
        builder: (BuildContext context, GoRouterState state) {
          return const ItineraryListScreen();
        },
      ),
      GoRoute(
        path: '/itinerary/new',
        builder: (_, _) => const ItineraryWriteScreen(itineraryId: null),
      ),
      GoRoute(
        path: '/itinerary/:itineraryId',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['itineraryId'] ?? '';
          return ItineraryDetailScreen(itineraryId: id);
        },
      ),
      GoRoute(
        path: '/itinerary/:itineraryId/edit',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['itineraryId'] ?? '';
          return ItineraryWriteScreen(itineraryId: id);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = user != null;

      final bool tryingToAccessProtected =
          state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/profile') ||
          state.matchedLocation.startsWith('/users/') ||
          state.matchedLocation.startsWith('/chat') ||
          state.matchedLocation.startsWith('/community') ||
          state.matchedLocation.startsWith('/itinerary') ||
          state.matchedLocation == '/settings/account' ||
          state.matchedLocation == '/matching/search' ||
          state.matchedLocation == '/report';
      final bool tryingToAccessAuth =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn && tryingToAccessProtected) {
        return '/login';
      }
      if (loggedIn && tryingToAccessAuth) {
        return '/';
      }

      return null;
    },
  );
}

/// /profile 접근 시 백엔드에서 현재 사용자 id를 조회한 뒤 /users/:userId로 리다이렉트.
/// Firebase 로그인은 되어 있으나 API 실패 시 로그인으로 보내지 않고 재시도/홈 버튼 표시.
class _ProfileRedirectScreen extends StatefulWidget {
  const _ProfileRedirectScreen();

  @override
  State<_ProfileRedirectScreen> createState() => _ProfileRedirectScreenState();
}

class _ProfileRedirectScreenState extends State<_ProfileRedirectScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    if (!mounted) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) GoRouter.of(context).go('/login');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = await authService.getCurrentBackendUserId();
    if (!mounted) return;
    if (userId != null && userId.isNotEmpty) {
      GoRouter.of(context).go('/users/${Uri.encodeComponent(userId)}');
      return;
    }
    setState(() { _loading = false; _error = '프로필 정보를 불러오지 못했습니다. API 주소와 네트워크를 확인한 뒤 재시도하세요.'; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _redirect, child: const Text('재시도')),
              const SizedBox(height: 8),
              TextButton(onPressed: () => GoRouter.of(context).go('/'), child: const Text('홈으로')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 신고 화면으로 잘못 진입했을 때(extra 없음) 홈으로 보냄.
class _RedirectToHome extends StatefulWidget {
  const _RedirectToHome();

  @override
  State<_RedirectToHome> createState() => _RedirectToHomeState();
}

class _RedirectToHomeState extends State<_RedirectToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GoRouter.of(context).go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
