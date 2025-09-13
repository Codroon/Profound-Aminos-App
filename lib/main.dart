import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:woo_management_app/firebase_options.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;

import 'core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize dependencies
  await di.init();

  runApp(const App());
}
