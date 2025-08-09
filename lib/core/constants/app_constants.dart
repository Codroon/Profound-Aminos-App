class AppConstants {
  // API
  static const String baseUrl = 'https://api.aviator-game.com/api/v1';
  static const String wsUrl = 'wss://ws.aviator-game.com';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String gameSettingsKey = 'game_settings';
  static const String themeKey = 'app_theme';

  // Game Constants
  static const double minBetAmount = 1.0;
  static const double maxBetAmount = 10000.0;
  static const double minMultiplier = 1.01;
  static const double maxMultiplier = 1000.0;
  static const int maxActiveBets = 2;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 1000);

  // Game States
  static const String gameStateWaiting = 'waiting';
  static const String gameStateFlying = 'flying';
  static const String gameStateCrashed = 'crashed';

  // Wallet
  static const double minDepositAmount = 10.0;
  static const double minWithdrawAmount = 20.0;

  // Pagination
  static const int defaultPageSize = 20;
  static const String faqText1 =
      'ATTENTION! Dear customer, sending payments from other wallets, including(jazzcash, Nayapay, Sadapay) or from bank accounts will not be accepted. Note that only easypaisa to easypaisa transfer is accepted for this method. Before filling the application below, please transfer using the account details given. KHABARDAAR! Mohtaram customer, kisi bhi aur wallet se payment bhejna, jaise ke (Jazzcash, Nayapay, Sadapay) ya bank account se, QABOOL nahi kiya jaye ga. Sirf easypaisa se easypaisa transfer is method ke liye QABOOL hai. Neeche diya gaya form fill karne se pehle, di gayi account details par transfer zarur karein.';
  static const String faqText2 =
      'ATTENTION! Dear customer, sending payments from other wallets, including(jazzcash, Nayapay, Sadapay) or from bank accounts will not be accepted. Note that only easypaisa to easypaisa transfer is accepted for this method. Before filling the application below, please transfer using the account details given. KHABARDAAR! Mohtaram customer, kisi bhi aur wallet se payment bhejna, jaise ke (Jazzcash, Nayapay, Sadapay) ya bank account se, QABOOL nahi kiya jaye ga. Sirf easypaisa se easypaisa transfer is method ke liye QABOOL hai. Neeche diya gaya form fill karne se pehle, di gayi account details par transfer zarur karein.';
  static const String cSupportText =
      'ATTENTION! Dear customer, sending payments from other wallets, including(jazzcash, Nayapay, Sadapay) or from bank accounts will not be accepted. Note that only easypaisa to easypaisa transfer is accepted for this ';
  static const String confirmWithdraw =
      'ATTENTION! Dear customer, sending payments from other wallets, including(jazzcash, Nayapay, Sadapay) or from bank accounts will not be accepted. Note that only easypaisa to easypaisa transfer is accepted for this method. Before filling the application below, please transfer using the account details given. KHABARDAAR! Mohtaram customer, kisi bhi aur wallet se payment bhejna, jaise ke (Jazzcash, Nayapay, Sadapay) ya bank account se, QABOOL nahi kiya jaye ga. Sirf easypaisa se easypaisa transfer is method ke liye QABOOL hai. Neeche diya gaya form fill karne se pehle, di gayi account details par transfer zarur karein.';
}
