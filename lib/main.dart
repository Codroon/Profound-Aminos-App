import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:woo_management_app/firebase_options.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;
import 'package:woo_management_app/core/services/push_notification_service.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } else {
    debugPrint('[Firebase] Already initialized by native system.');
  }

  await di.init();

  PushNotificationService.instance.initialize().catchError((e) {
    debugPrint('[PushNotification] Init failed: $e');
  });

  runApp(const App());
}