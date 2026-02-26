/// 루트 위젯. 로그인 상태에 따라 라우터를 동적으로 구성하고 MaterialApp.router로 표시.
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/router.dart';
import 'package:travel_mate_app/app/theme.dart';

class TravelMateApp extends StatelessWidget {
  const TravelMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();
    final GoRouter appRouter = createRouter(user);
    return MaterialApp.router(
      title: 'TravelMate',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}