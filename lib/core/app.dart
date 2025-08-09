import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woo_management_app/core/routes/app_routes.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_event.dart';
import '../features/home/presentation/pages/bottom_nav_page.dart';
import '../features/auth/presentation/pages/admin_login_screen.dart';
import '../widgets/custom_loading_widget.dart';
import 'theme/app_theme.dart';
import 'di/injection_container.dart' as di;

class App extends StatelessWidget {
  const App({super.key});

  Future<bool> checkCredentialsExist() async {
    const secureStorage = FlutterSecureStorage();
    final wooKey = await secureStorage.read(key: 'wooKey');
    return wooKey != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<AnalyticsBloc>()..add(const FetchAnalytics(0)),
      child: MaterialApp(
        title: 'Profound Aminon',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: checkCredentialsExist(),
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
      ),
    );
  }
}
