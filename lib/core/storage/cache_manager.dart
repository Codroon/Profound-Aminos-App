import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';
import '../error/exceptions.dart';

class CacheItem<T> {
  final T data;
  final DateTime expiryTime;

  CacheItem({required this.data, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  Map<String, dynamic> toJson() {
    return {'data': data, 'expiryTime': expiryTime.toIso8601String()};
  }

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      data: json['data'] as T,
      expiryTime: DateTime.parse(json['expiryTime'] as String),
    );
  }
}

class CacheManager {
  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  Future<void> cacheData<T>(
    String key,
    T data, {
    Duration duration = StorageConstants.mediumCacheDuration,
  }) async {
    try {
      final expiryTime = DateTime.now().add(duration);
      final cacheItem = CacheItem<T>(data: data, expiryTime: expiryTime);

      String cacheData;
      if (T == String || T == int || T == double || T == bool) {
        cacheData = jsonEncode({
          'data': data,
          'expiryTime': expiryTime.toIso8601String(),
        });
      } else if (data is Map || data is List) {
        cacheData = jsonEncode({
          'data': data,
          'expiryTime': expiryTime.toIso8601String(),
        });
      } else {
        throw CacheException(message: 'Unsupported type for caching');
      }

      await _prefs.setString('${StorageConstants.cacheBox}_$key', cacheData);
    } catch (e) {
      throw CacheException(message: 'Failed to cache data: ${e.toString()}');
    }
  }

  Future<T?> getCachedData<T>(String key) async {
    try {
      final cacheData = _prefs.getString('${StorageConstants.cacheBox}_$key');
      if (cacheData == null) return null;

      final decodedData = jsonDecode(cacheData) as Map<String, dynamic>;
      final expiryTime = DateTime.parse(decodedData['expiryTime'] as String);

      if (DateTime.now().isAfter(expiryTime)) {
        // Cache expired, remove it
        await _prefs.remove('${StorageConstants.cacheBox}_$key');
        return null;
      }

      return decodedData['data'] as T;
    } catch (e) {
      throw CacheException(
        message: 'Failed to get cached data: ${e.toString()}',
      );
    }
  }

  Future<void> removeCachedData(String key) async {
    await _prefs.remove('${StorageConstants.cacheBox}_$key');
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where(
      (key) => key.startsWith('${StorageConstants.cacheBox}_'),
    );

    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }

  Future<void> removeExpiredCache() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where(
      (key) => key.startsWith('${StorageConstants.cacheBox}_'),
    );

    for (final key in cacheKeys) {
      final cacheData = _prefs.getString(key);
      if (cacheData != null) {
        try {
          final decodedData = jsonDecode(cacheData) as Map<String, dynamic>;
          final expiryTime = DateTime.parse(
            decodedData['expiryTime'] as String,
          );

          if (DateTime.now().isAfter(expiryTime)) {
            await _prefs.remove(key);
          }
        } catch (e) {
          // If we can't parse the cache data, remove it
          await _prefs.remove(key);
        }
      }
    }
  }
}
