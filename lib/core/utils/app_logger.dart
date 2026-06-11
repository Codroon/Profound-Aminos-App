import 'package:flutter/foundation.dart';

/// Lightweight, tagged logger that prints to the console reliably in BOTH
/// the VS Code terminal (`flutter run` / Debug Console) and the native Xcode
/// console. We use [debugPrint] (not dart:developer log) because the latter
/// often does not surface in Xcode's console or the plain run terminal.
///
/// Use this for tracing background API activity so it's easy to watch exactly
/// when each request fires, how long it took, and whether it hit the network,
/// the cache, or timed out.
class AppLog {
  AppLog._();

  static void net(String tag, String message) =>
      debugPrint('🌐 [$tag] $message');

  static void cache(String tag, String message) =>
      debugPrint('📦 [$tag] $message');

  static void ok(String tag, String message) =>
      debugPrint('✅ [$tag] $message');

  static void refresh(String tag, String message) =>
      debugPrint('🔄 [$tag] $message');

  static void timeout(String tag, String message) =>
      debugPrint('⏱️ [$tag] $message');

  static void error(String tag, String message) =>
      debugPrint('❌ [$tag] $message');
}
