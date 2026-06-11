import '../../../../core/utils/store_time.dart';

/// Time range options for filtering the shipping dashboard.
///
/// [after]/[before] map to the WooCommerce `after`/`before` order query
/// params. `before` is left null (meaning "up to now") for every period.
/// Boundaries use the store's wall-clock time so "today" is the store's
/// calendar day, not the device's.
enum ShipmentPeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  allTime('All Time');

  final String label;
  const ShipmentPeriod(this.label);

  /// Inclusive start of the range. `null` for [allTime] (no lower bound).
  DateTime? get after {
    final now = StoreTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (this) {
      case ShipmentPeriod.today:
        return startOfToday;
      case ShipmentPeriod.thisWeek:
        // Monday as the first day of the week.
        return startOfToday.subtract(Duration(days: now.weekday - 1));
      case ShipmentPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ShipmentPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ShipmentPeriod.allTime:
        return null;
    }
  }

  /// Upper bound of the range. Always `null` (up to the present moment).
  DateTime? get before => null;
}
