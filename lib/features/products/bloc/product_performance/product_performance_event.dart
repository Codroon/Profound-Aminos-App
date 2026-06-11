import 'package:equatable/equatable.dart';

/// Period options for the top chart card.
enum ProductPeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  allTime('All Time');

  const ProductPeriod(this.label);
  final String label;
}

/// Period options for the bottom "Top Products" ranking card.
enum TopProductsPeriod { today, lastWeek, lastMonth, lastYear }

abstract class ProductPerformanceEvent extends Equatable {
  const ProductPerformanceEvent();
  @override
  List<Object?> get props => [];
}

/// Load the chart (sold count + time series) for the given [period].
class LoadProductChart extends ProductPerformanceEvent {
  final ProductPeriod period;
  const LoadProductChart(this.period);
  @override
  List<Object?> get props => [period];
}

/// Load the top-products ranking for the given [period].
class LoadTopProducts extends ProductPerformanceEvent {
  final TopProductsPeriod period;
  const LoadTopProducts(this.period);
  @override
  List<Object?> get props => [period];
}

/// Reveal the next page of the already-loaded top-products list (the list is
/// fetched in full, but shown 10 at a time via "Load More").
class ShowMoreTopProducts extends ProductPerformanceEvent {
  const ShowMoreTopProducts();
}
