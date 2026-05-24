import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woo_management_app/core/routes/app_routes.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_bloc.dart';
import 'package:woo_management_app/features/notifications/bloc/notifications_bloc.dart';
import '../features/home/presentation/pages/bottom_nav_page.dart';
import '../features/auth/presentation/pages/admin_login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'di/injection_container.dart' as di;
import 'services/credential_initialization_service.dart';
import '../features/shipping/bloc/shipping_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _showHome = false;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  @override
  void initState() {
    super.initState();
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    try {
      final wooKey = await _storage
          .read(key: 'wooKey')
          .timeout(const Duration(seconds: 3));

      if (wooKey == null || wooKey.isEmpty) {
        debugPrint('[App] No credentials found — showing login.');
        return;
      }

      await CredentialInitializationService().initializeCredentials().timeout(
        const Duration(seconds: 5),
      );

      debugPrint('[App] Credentials restored — navigating to home.');
      if (mounted) {
        setState(() => _showHome = true);
      }
    } catch (e) {
      debugPrint('[App] Session restore failed: $e');
      try {
        await _storage.deleteAll().timeout(const Duration(seconds: 2));
      } catch (_) {}
      // Already showing login, nothing else needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AnalyticsBloc>()),
        BlocProvider(create: (_) => di.sl<GorgiasBloc>()),
        BlocProvider(create: (_) => di.sl<ProductBloc>()),
        BlocProvider(create: (_) => di.sl<ShippingBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationsBloc>()..add(LoadNotifications())),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeManager.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            navigatorKey: AppRouter.navigatorKey,
            key: ValueKey(themeMode),
            title: 'Profound Aminon',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            home: _showHome ? const BottomNavScreen() : const AdminLoginPage(),
          );
        },
      ),
    );
  }
}
