enum RevenuePeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  allTime('All Time');

  const RevenuePeriod(this.label);
  final String label;
}
