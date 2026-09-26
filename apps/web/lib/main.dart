import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/auth/auth_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/dashboard/shipment_pages.dart';
import 'features/dashboard/admin_wallet_page.dart';
import 'core/api_client.dart';
import 'features/auth/verification_page.dart';
import 'features/auth/password_reset_page.dart';

void main() {
  runApp(const SecureByPayApp());
  apiClient.restoreSession();
}

class SecureByPayApp extends StatelessWidget {
  const SecureByPayApp({super.key});

  static final _router = GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: apiClient.authState,
    redirect: (_, state) {
      const publicPaths = {
        '/sign-in',
        '/sign-up',
        '/verify',
        '/forgot-password',
        '/reset-password'
      };
      final isPublic = publicPaths.contains(state.uri.path);
      if (!apiClient.isAuthenticated && !isPublic) {
        return '/sign-in';
      }
      if (apiClient.isAuthenticated &&
          (state.uri.path == '/sign-in' || state.uri.path == '/sign-up')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/sign-in',
          builder: (_, __) => const AuthPage(mode: AuthMode.signIn)),
      GoRoute(
          path: '/sign-up',
          builder: (_, __) => const AuthPage(mode: AuthMode.signUp)),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
      GoRoute(path: '/shipments', builder: (_, __) => const ShipmentsPage()),
      GoRoute(
          path: '/admin/wallet', builder: (_, __) => const AdminWalletPage()),
      GoRoute(
          path: '/shipments/:id',
          builder: (_, state) =>
              ShipmentDetailPage(shipmentId: state.pathParameters['id'] ?? '')),
      GoRoute(
          path: '/verify',
          builder: (_, state) => VerificationPage(
                challengeId: state.uri.queryParameters['challengeId'] ?? '',
                destination:
                    state.uri.queryParameters['destination'] ?? 'your email',
                purpose: state.uri.queryParameters['purpose'] ?? 'login',
              )),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const PasswordResetRequestPage()),
      GoRoute(
          path: '/reset-password',
          builder: (_, state) => PasswordResetPage(
              challengeId: state.uri.queryParameters['challengeId'] ?? '')),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SecureByPay',
        theme: buildTheme(),
        routerConfig: _router,
      );
}
