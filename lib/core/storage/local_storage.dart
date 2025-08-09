import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';
import '../error/exceptions.dart';

abstract class LocalStorage {
  // Auth
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String refreshToken);
  Future<bool> isLoggedIn();
  Future<void> setLoggedIn(bool isLoggedIn);
  Future<void> clearAuthData();

  // User
  Future<Map<String, dynamic>?> getUserData();
  Future<void> saveUserData(Map<String, dynamic> userData);

  // Game
  Future<List<Map<String, dynamic>>?> getGameHistory();
  Future<void> saveGameHistory(List<Map<String, dynamic>> history);
  Future<Map<String, dynamic>?> getGameSettings();
  Future<void> saveGameSettings(Map<String, dynamic> settings);

  // Wallet
  Future<double?> getBalance();
  Future<void> saveBalance(double balance);

  // Settings
  Future<String?> getTheme();
  Future<void> saveTheme(String theme);
  Future<bool> getSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);

  // General
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value);
  Future<void> remove(String key);
  Future<void> clear();
}

class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;

  LocalStorageImpl(this._prefs);

  // Auth
  @override
  Future<String?> getToken() async {
    return _prefs.getString(StorageConstants.tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageConstants.tokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(StorageConstants.refreshTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await _prefs.setString(StorageConstants.refreshTokenKey, refreshToken);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(StorageConstants.isLoggedInKey) ?? false;
  }

  @override
  Future<void> setLoggedIn(bool isLoggedIn) async {
    await _prefs.setBool(StorageConstants.isLoggedInKey, isLoggedIn);
  }

  @override
  Future<void> clearAuthData() async {
    await _prefs.remove(StorageConstants.tokenKey);
    await _prefs.remove(StorageConstants.refreshTokenKey);
    await _prefs.remove(StorageConstants.userIdKey);
    await _prefs.remove(StorageConstants.isLoggedInKey);
  }

  // User
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = _prefs.getString(StorageConstants.userDataKey);
    if (userDataString == null) return null;

    try {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException(message: 'Failed to parse user data');
    }
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userDataString = jsonEncode(userData);
      await _prefs.setString(StorageConstants.userDataKey, userDataString);
    } catch (e) {
      throw CacheException(message: 'Failed to save user data');
    }
  }

  // Game
  @override
  Future<List<Map<String, dynamic>>?> getGameHistory() async {
    final historyString = _prefs.getString(StorageConstants.gameHistoryKey);
    if (historyString == null) return null;

    try {
      final historyList = jsonDecode(historyString) as List;
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      throw CacheException(message: 'Failed to parse game history');
    }
  }

  @override
  Future<void> saveGameHistory(List<Map<String, dynamic>> history) async {
    try {
      final historyString = jsonEncode(history);
      await _prefs.setString(StorageConstants.gameHistoryKey, historyString);
    } catch (e) {
      throw CacheException(message: 'Failed to save game history');
    }
  }

  @override
  Future<Map<String, dynamic>?> getGameSettings() async {
    final settingsString = _prefs.getString(StorageConstants.gameSettingsKey);
    if (settingsString == null) return null;

    try {
      return jsonDecode(settingsString) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException(message: 'Failed to parse game settings');
    }
  }

  @override
  Future<void> saveGameSettings(Map<String, dynamic> settings) async {
    try {
      final settingsString = jsonEncode(settings);
      await _prefs.setString(StorageConstants.gameSettingsKey, settingsString);
    } catch (e) {
      throw CacheException(message: 'Failed to save game settings');
    }
  }

  // Wallet
  @override
  Future<double?> getBalance() async {
    return _prefs.getDouble(StorageConstants.balanceKey);
  }

  @override
  Future<void> saveBalance(double balance) async {
    await _prefs.setDouble(StorageConstants.balanceKey, balance);
  }

  // Settings
  @override
  Future<String?> getTheme() async {
    return _prefs.getString(StorageConstants.themeKey);
  }

  @override
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(StorageConstants.themeKey, theme);
  }

  @override
  Future<bool> getSoundEnabled() async {
    return _prefs.getBool(StorageConstants.soundEnabledKey) ?? true;
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(StorageConstants.soundEnabledKey, enabled);
  }

  // General
  @override
  Future<T?> get<T>(String key) async {
    return _prefs.get(key) as T?;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      throw CacheException(message: 'Unsupported type for SharedPreferences');
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
