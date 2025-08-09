class StorageConstants {
  // Hive Box Names
  static const String authBox = 'auth_box';
  static const String gameBox = 'game_box';
  static const String walletBox = 'wallet_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Auth Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  // Game Storage Keys
  static const String gameHistoryKey = 'game_history';
  static const String gameSettingsKey = 'game_settings';
  static const String lastBetAmountKey = 'last_bet_amount';
  static const String autoCashoutKey = 'auto_cashout';

  // Wallet Storage Keys
  static const String balanceKey = 'wallet_balance';
  static const String transactionsKey = 'transactions';
  static const String paymentMethodsKey = 'payment_methods';

  // Settings Storage Keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';

  // Cache Duration
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(days: 1);
}
