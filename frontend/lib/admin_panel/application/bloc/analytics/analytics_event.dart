part of 'analytics_bloc.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {
  final String businessSlug;
  final String? startDate;
  final String? endDate;

  const LoadAnalytics({
    required this.businessSlug,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [businessSlug, startDate, endDate];
}

