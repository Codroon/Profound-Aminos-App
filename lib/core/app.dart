import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woo_management_app/core/routes/app_routes.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_event.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_event.dart';
import '../features/home/presentation/pages/bottom_nav_page.dart';
import '../features/auth/presentation/pages/admin_login_screen.dart';
import '../features/reach_ship/bloc/reach_ship_bloc.dart';
import '../widgets/custom_loading_widget.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'di/injection_container.dart' as di;
import 'services/credential_initialization_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<bool> checkAndInitializeCredentials() async {
    const secureStorage = FlutterSecureStorage();
    final wooKey = await secureStorage.read(key: 'wooKey');

    if (wooKey != null) {
      // Credentials exist, initialize them
      try {
        await CredentialInitializationService().initializeCredentials();
        return true;
      } catch (e) {
        print('[App] Failed to initialize credentials: $e');
        return false;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AnalyticsBloc>()..add(const FetchAnalytics(0)),
        ),
        BlocProvider(create: (_) => di.sl<GorgiasBloc>()),
        BlocProvider(create: (_) => di.sl<ReachShipBloc>()),
        BlocProvider(
          create: (_) => di.sl<ProductBloc>()..add(const FetchProducts(page: 1, perPage: 20, forceRefresh: true)),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeManager.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Profound Aminon',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            home: FutureBuilder<bool>(
              future: checkAndInitializeCredentials(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CustomLoadingWidget(text: 'Loading... Please wait'),
                    ),
                  );
                }
                if (snapshot.data == true) {
                  return const BottomNavScreen();
                } else {
                  return const AdminLoginPage();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
