import '../services/woocommerce_service.dart';
import 'app_logger.dart';

/// Store-timezone–aware clock.
///
/// WooCommerce interprets bare `after`/`before` date filters (and the
/// `wc-analytics` report `intervals`) in the **store's** configured timezone,
/// not the device's. Computing "today / this week / this month" from the
/// device clock therefore queries the wrong window for any admin who isn't in
/// the store's timezone — e.g. a manager in Pakistan sees 0 orders for "today"
/// while the US store is still on the previous calendar day.
///
/// This caches the store's UTC offset (loaded once from the WordPress REST
/// root) and exposes a store-local "now" plus an offset suffix to stamp onto
/// API date strings so WooCommerce never has to guess the timezone.
///
/// Until the offset has loaded, every accessor falls back to the device's
/// local time — i.e. the previous behaviour — rather than guessing.
class StoreTime {
  StoreTime._();

  static Duration? _offset;
  static Future<void>? _loadFuture;

  /// True once the real store offset has been loaded.
  static bool get isLoaded => _offset != null;

  /// Manual override (tests / explicit config).
  static void setOffset(Duration offset) => _offset = offset;

  /// Clear the cached offset — call when credentials change / on logout.
  static void reset() {
    _offset = null;
    _loadFuture = null;
  }

  /// "Now" expressed in the store's wall-clock time. Returned as a
  /// local-flagged [DateTime] whose y/m/d/h fields are the store's local
  /// fields, so it composes with WooCommerce's offset-less interval
  /// timestamps via plain field math (`d.hour`, `d.weekday`, …).
  static DateTime now() {
    final off = _offset;
    if (off == null) return DateTime.now();
    final wall = DateTime.now().toUtc().add(off);
    return DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute,
        wall.second, wall.millisecond);
  }

  /// Offset suffix for ISO date strings, e.g. `-07:00` / `+05:30`. Empty while
  /// the offset hasn't loaded so the string stays device-local (old behaviour).
  static String get offsetSuffix {
    final off = _offset;
    if (off == null) return '';
    final sign = off.isNegative ? '-' : '+';
    final abs = off.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  /// Serialise a store-wall [DateTime] to a full WooCommerce date string with
  /// the store offset stamped on, e.g. `2026-06-10T00:00:00-07:00`. Used for
  /// the shipping filter, which passes [DateTime] objects rather than strings.
  static String toApiString(DateTime storeWall) {
    String p(int v) => v.toString().padLeft(2, '0');
    final date = '${storeWall.year}-${p(storeWall.month)}-${p(storeWall.day)}';
    final time =
        '${p(storeWall.hour)}:${p(storeWall.minute)}:${p(storeWall.second)}';
    return '${date}T$time$offsetSuffix';
  }

  /// Loads the store's UTC offset from the WordPress REST root (`gmt_offset`).
  /// Safe to call repeatedly and concurrently: a load already in flight is
  /// shared, so concurrent callers *await the same fetch* rather than racing
  /// past it. Retries on the next call if the previous attempt failed.
  static Future<void> ensureLoaded() {
    if (_offset != null) return Future.value();
    return _loadFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      final hours = await WooCommerceService().fetchStoreGmtOffset();
      if (hours != null) {
        _offset = Duration(minutes: (hours * 60).round());
        AppLog.ok('StoreTime', 'store gmt_offset = ${hours}h → $offsetSuffix');
      }
    } catch (e) {
      AppLog.error('StoreTime', 'failed to load store offset: $e');
    } finally {
      // Clear so a failed attempt can be retried; a success leaves _offset set
      // and ensureLoaded() short-circuits before reaching here next time.
      _loadFuture = null;
    }
  }
}
