class ApiConstants {
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Game Endpoints
  static const String gameState = '/game/state';
  static const String gameHistory = '/game/history';
  static const String placeBet = '/game/bet';
  static const String cashOut = '/game/cash-out';

  // Wallet Endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String deposit = '/wallet/deposit';
  static const String withdraw = '/wallet/withdraw';
  static const String paymentMethods = '/wallet/payment-methods';

  // Profile Endpoints
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String changePassword = '/profile/change-password';
  static const String settings = '/profile/settings';

  // Leaderboard Endpoints
  static const String leaderboard = '/leaderboard';
  static const String playerRank = '/leaderboard/rank';

  // Notifications Endpoints
  static const String notifications = '/notifications';
  static const String markAsRead = '/notifications/mark-read';

  // WebSocket Events
  static const String wsGameStart = 'game_start';
  static const String wsGameUpdate = 'game_update';
  static const String wsGameEnd = 'game_end';
  static const String wsBetPlaced = 'bet_placed';
  static const String wsCashOut = 'cash_out';
  static const String wsBalanceUpdate = 'balance_update';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Error Codes
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int serverErrorCode = 500;
}
