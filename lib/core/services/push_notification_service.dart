import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woo_management_app/core/routes/app_routes.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/widgets/in_app_notification_banner.dart';
import 'package:woo_management_app/features/notifications/models/app_notification.dart';
import 'package:woo_management_app/features/notifications/services/notification_storage_service.dart';
import 'package:woo_management_app/features/notifications/bloc/notifications_bloc.dart';
import 'package:woo_management_app/features/notifications/services/notification_preference_service.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;

Future<void> _saveNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;
  final appNotification = AppNotification(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: notification.title ?? '',
    body: notification.body ?? '',
    data: message.data,
    timestamp: message.sentTime ?? DateTime.now(),
    isRead: false,
  );
  await NotificationStorageService().saveNotification(appNotification);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[PushNotification] Background message: ${message.messageId}');
  final type = message.data['type']?.toString() ?? '';
  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';
  final enabled = await NotificationPreferenceService.isNotificationEnabled(
    type: type,
    title: title,
    body: body,
  );
  if (!enabled) {
    debugPrint('[PushNotification] Push notification is disabled by user settings. Ignoring.');
    return;
  }
  await _saveNotification(message);
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // KEY FIX: single shared instance with resetOnError to prevent Keystore hang
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  bool _isInitialized = false;

  static const AndroidNotificationChannel _ordersChannel =
      AndroidNotificationChannel(
        'orders_channel',
        'Orders',
        description: 'Notifications for new and updated WooCommerce orders.',
        importance: Importance.high,
        playSound: true,
      );

  static const AndroidNotificationChannel _supportChannel =
      AndroidNotificationChannel(
        'support_channel',
        'Support Tickets',
        description: 'Notifications for Gorgias support tickets and messages.',
        importance: Importance.high,
        playSound: true,
      );

  static const AndroidNotificationChannel _shippingChannel =
      AndroidNotificationChannel(
        'shipping_channel',
        'Shipping',
        description: 'Notifications for shipment and tracking updates.',
        importance: Importance.high,
        playSound: true,
      );

  Future<void> initialize() async {
    if (_isInitialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _createNotificationChannels();
    await _initializeLocalNotifications();
    await _requestPermissions();

    // KEY FIX: non-blocking — token failure must never hang startup
    _handleToken().catchError((e) {
      debugPrint('[PushNotification] Token handling failed: $e');
    });

    _messaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token).catchError((e) {
        debugPrint('[PushNotification] Token refresh save failed: $e');
      });
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // KEY FIX: non-blocking
    _messaging
        .getInitialMessage()
        .then((message) {
          if (message != null) _handleNotificationTap(message);
        })
        .catchError((e) {
          debugPrint('[PushNotification] getInitialMessage failed: $e');
        });

    _isInitialized = true;
    debugPrint('[PushNotification] Service initialized successfully.');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_ordersChannel);
      await androidPlugin.createNotificationChannel(_supportChannel);
      await androidPlugin.createNotificationChannel(_shippingChannel);
      debugPrint('[PushNotification] Android notification channels created.');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
      '[PushNotification] Permission status: ${settings.authorizationStatus}',
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  Future<void> _handleToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken().timeout(
          const Duration(seconds: 5),
        );
        if (apnsToken == null) {
          debugPrint(
            '[PushNotification] APNs token not yet available. '
            'FCM token will be retrieved on next launch.',
          );
          return;
        }
      }

      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 5),
      );

      if (token != null) {
        debugPrint(
          '[PushNotification] FCM Token: ${token.substring(0, 20)}...',
        );
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[PushNotification] Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      // KEY FIX: timeout + resetOnError prevents Keystore hang
      final wooUrl = await _secureStorage
          .read(key: 'wooUrl')
          .timeout(const Duration(seconds: 3));

      if (wooUrl == null || wooUrl.isEmpty) {
        debugPrint('[PushNotification] No wooUrl found — skipping token save.');
        return;
      }

      final deviceId = '${Platform.operatingSystem}_${token.hashCode.abs()}';

      // Read local preferences to sync with backend
      final prefs = await SharedPreferences.getInstance();
      final preferences = {
        'orders_create': prefs.getBool('pref_orders_create') ?? true,
        'orders_update': prefs.getBool('pref_orders_update') ?? true,
        'orders_refund': prefs.getBool('pref_orders_refund') ?? true,
        'shipment_create': prefs.getBool('pref_shipment_create') ?? true,
        'shipment_update': prefs.getBool('pref_shipment_update') ?? true,
        'shipment_delivered': prefs.getBool('pref_shipment_delivered') ?? true,
        'gorgias_create': prefs.getBool('pref_gorgias_create') ?? true,
        'gorgias_update': prefs.getBool('pref_gorgias_update') ?? true,
        'gorgias_message': prefs.getBool('pref_gorgias_message') ?? true,
      };

      await FirebaseFirestore.instance
          .collection('admin_devices')
          .doc(deviceId)
          .set({
            'token': token,
            'platform': Platform.operatingSystem,
            'wooUrl': wooUrl,
            'updatedAt': FieldValue.serverTimestamp(),
            'preferences': preferences,
          }, SetOptions(merge: true));

      debugPrint('[PushNotification] Token and preferences saved to Firestore.');
    } catch (e) {
      debugPrint('[PushNotification] Error saving token: $e');
    }
  }

  Future<void> syncPreferences() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[PushNotification] Error syncing preferences: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '[PushNotification] Foreground message received: ${message.notification?.title}',
    );
    
    final type = message.data['type']?.toString() ?? '';
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final enabled = await NotificationPreferenceService.isNotificationEnabled(
      type: type,
      title: title,
      body: body,
    );
    if (!enabled) {
      debugPrint('[PushNotification] Push notification is disabled by user settings. Skipping foreground delivery.');
      return;
    }
    
    await _saveNotification(message);
    try {
      di.sl<NotificationsBloc>().add(LoadNotifications());
    } catch (_) {}

    final notification = message.notification;
    if (notification == null) return;

    final channelId = _resolveChannelId(message.data);

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    debugPrint('[PushNotification] Active Navigator Overlay found: ${overlayState != null}');
    if (overlayState != null) {
      final updatedData = Map<String, dynamic>.from(message.data);
      updatedData['channelId'] = channelId;

      debugPrint('[PushNotification] Displaying Custom In-App Sliding Banner...');
      InAppNotificationBanner.show(
        overlayState: overlayState,
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        data: updatedData,
        onTap: () => navigateToScreen(updatedData),
      );
    } else {
      debugPrint('[PushNotification] Warning: Navigator Overlay was null. In-app banner skipped.');
    }
  }

  String _resolveChannelId(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type.startsWith('order') ||
        type.startsWith('shipment') ||
        type.startsWith('tracking')) {
      if (type.startsWith('shipment') || type.startsWith('tracking')) {
        return _shippingChannel.id;
      }
      return _ordersChannel.id;
    }
    if (type.startsWith('ticket') || type.startsWith('message')) {
      return _supportChannel.id;
    }
    return _ordersChannel.id;
  }


  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[PushNotification] Notification tapped: ${message.data}');
    navigateToScreen(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint(
      '[PushNotification] Local notification tapped: ${response.payload}',
    );
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        navigateToScreen(data);
      } catch (e) {
        debugPrint(
          '[PushNotification] Error parsing local notification payload: $e',
        );
      }
    }
  }

  void navigateToScreen(Map<String, dynamic> data) {
    debugPrint('[PushNotification] Deep link navigation triggered: $data');
    final type = data['type']?.toString() ?? '';
    final orderId = data['order_id']?.toString();
    final ticketId = data['ticket_id']?.toString();
    final shipmentId = data['shipment_id']?.toString() ?? orderId;

    if (AppRouter.navigatorKey.currentState == null) {
      debugPrint('[PushNotification] NavigatorState is not ready yet!');
      return;
    }

    if (type.startsWith('order')) {
      AppRouter.navigatorKey.currentState?.pushNamed(
        RouteNames.wooAllOrders,
        arguments: orderId,
      );
    } else if (type.startsWith('ticket') || type.startsWith('message')) {
      AppRouter.navigatorKey.currentState?.pushNamed(
        RouteNames.gorgiasDashboard,
        arguments: ticketId,
      );
    } else if (type.startsWith('shipment') ||
        type.startsWith('tracking') ||
        type == 'shipping') {
      AppRouter.navigatorKey.currentState?.pushNamed(
        RouteNames.shipments,
        arguments: shipmentId,
      );
    } else {
      final channelId = data['channelId']?.toString() ?? '';
      if (channelId == 'orders_channel') {
        AppRouter.navigatorKey.currentState?.pushNamed(
          RouteNames.wooAllOrders,
          arguments: orderId,
        );
      } else if (channelId == 'support_channel') {
        AppRouter.navigatorKey.currentState?.pushNamed(
          RouteNames.gorgiasDashboard,
          arguments: ticketId,
        );
      } else if (channelId == 'shipping_channel') {
        AppRouter.navigatorKey.currentState?.pushNamed(
          RouteNames.shipments,
          arguments: shipmentId,
        );
      }
    }
  }
}
