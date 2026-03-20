import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/screens/leaderboard_page.dart';
import '../screens/login_page.dart';
import '../screens/home_page.dart';
import '../screens/game_page.dart';
import '../screens/end_page.dart';
import '../screens/panduan_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardPage(),
    ),
    GoRoute(path: '/game', builder: (context, state) => const GamePage()),
    GoRoute(path: '/panduan', builder: (context, state) => const PanduanPage()),
    GoRoute(
      path: '/end/:playerName/:money',
      builder: (context, state) {
        final playerName = state.pathParameters['playerName'] ?? 'Guest';
        final moneyStr = state.pathParameters['money'] ?? '0';
        final totalMoney = int.tryParse(moneyStr) ?? 0;

        return EndPage(
          playerName: Uri.decodeComponent(playerName),
          totalMoney: totalMoney,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFFFFB300),
    body: Center(
      child: Text(
        'Halaman tidak ditemukan\n${state.error}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black, fontSize: 18),
      ),
    ),
  ),
);
