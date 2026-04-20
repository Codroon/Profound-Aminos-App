import 'package:equatable/equatable.dart';
import '../models/revenue_period.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAnalytics extends AnalyticsEvent {
  final int tabIndex;
  const FetchAnalytics(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class FetchRevenueReport extends AnalyticsEvent {
  final RevenuePeriod period;
  const FetchRevenueReport(this.period);
  @override
  List<Object?> get props => [period];
}