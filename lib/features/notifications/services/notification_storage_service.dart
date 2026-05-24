import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationStorageService {
  static const String _storageKey = 'app_notifications_list';

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedJsonList = prefs.getStringList(_storageKey);
    
    if (storedJsonList == null) return [];

    return storedJsonList
        .map((jsonStr) => AppNotification.fromJson(jsonStr))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveNotification(AppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    // Check if notification with same ID already exists to prevent duplicates
    if (!notifications.any((n) => n.id == notification.id)) {
      notifications.add(notification);
      
      final updatedJsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setStringList(_storageKey, updatedJsonList);
    }
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      final updatedJsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setStringList(_storageKey, updatedJsonList);
    }
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    final updatedList = notifications.map((n) => n.copyWith(isRead: true)).toList();
    final updatedJsonList = updatedList.map((n) => n.toJson()).toList();
    await prefs.setStringList(_storageKey, updatedJsonList);
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    notifications.removeWhere((n) => n.id == id);
    
    final updatedJsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setStringList(_storageKey, updatedJsonList);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
