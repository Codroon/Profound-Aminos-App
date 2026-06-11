import 'package:equatable/equatable.dart';
import '../models/revenue_period.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAnalytics extends AnalyticsEvent {
  final int tabIndex;

  /// Period the revenue/orders chart should open on once the base data
  /// resolves. Defaults to [RevenuePeriod.thisWeek] (Revenue screen); the
  /// Orders screen passes [RevenuePeriod.today].
  final RevenuePeriod initialPeriod;

  const FetchAnalytics(this.tabIndex,
      {this.initialPeriod = RevenuePeriod.thisWeek});
  @override
  List<Object?> get props => [tabIndex, initialPeriod];
}

class FetchRevenueReport extends AnalyticsEvent {
  final RevenuePeriod period;
  const FetchRevenueReport(this.period);
  @override
  List<Object?> get props => [period];
}