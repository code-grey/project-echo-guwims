import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/admin_user_screen.dart';
import '../../features/grievance/presentation/screens/dashboard_screen.dart';
import '../../features/grievance/presentation/screens/workforce_queue_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.path == '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) {
        final role = authState.user?.role;
        if (role == 'ADMIN') return '/admin';
        if (role == 'SANITATION_WORKER' ||
            role == 'ELECTRICIAN' ||
            role == 'SECURITY') {
          return '/workforce';
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/workforce',
        builder: (context, state) => const WorkforceQueueScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const DashboardScreen(), 
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUserScreen(),
      ),
    ],
  );
});
