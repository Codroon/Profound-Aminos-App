import 'package:equatable/equatable.dart';

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