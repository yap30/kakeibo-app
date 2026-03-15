import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/auth_pages.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/transaction_history_page.dart';
import '../../features/savings/presentation/pages/savings_page.dart';
import '../../features/reflections/presentation/pages/reflection_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../shell/main_shell.dart';
import '../../features/dashboard/presentation/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.maybeWhen(
        data: (auth) => auth.session != null,
        orElse: () => false,
      );

      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/history', builder: (_, __) => const TransactionHistoryPage()),
          GoRoute(path: '/savings', builder: (_, __) => const SavingsPage()),
          GoRoute(path: '/reflect', builder: (_, __) => const ReflectionPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),

      // Add transaction (full screen modal)
      GoRoute(
        path: '/add-transaction',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AddTransactionPage(),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
