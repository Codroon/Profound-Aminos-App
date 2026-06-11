import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../core/routes/routes_name.dart';
import '../../../../widgets/custom_progress_bar.dart';
import '../../../gorgias/bloc/gorgias_bloc.dart';
import '../../../gorgias/bloc/gorgias_event.dart';
import '../../../gorgias/bloc/gorgias_state.dart';

class GorgiasCard extends StatefulWidget {
  final int? cachedOpenTickets;
  final int? cachedClosedTickets;
  final int? cachedTotalTickets;
  
  const GorgiasCard({
    super.key,
    this.cachedOpenTickets,
    this.cachedClosedTickets,
    this.cachedTotalTickets,
  });

  @override
  State<GorgiasCard> createState() => _GorgiasCardState();
}

class _GorgiasCardState extends State<GorgiasCard> {
  bool _hasInitialized = false;
  Timer? _retryTimer;
  
  // Use cached data if available
  bool get _hasCachedData => 
      widget.cachedOpenTickets != null && 
      widget.cachedClosedTickets != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Only fetch if no cached data - otherwise wait for background refresh
      if (!_hasCachedData) {
        _fetchTicketStatsWithRetry();
      }
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _fetchTicketStatsWithRetry() {
    final currentState = context.read<GorgiasBloc>().state;
    if (currentState is! TicketStatsLoaded && currentState is! TicketStatsLoading) {
      context.read<GorgiasBloc>().add(const FetchTicketStats());
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _fetchTicketStatsWithRetry();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.gorgiasDashboard);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                AppReusableText(
                  text: 'Gorgias',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const Gap(8),
            BlocConsumer<GorgiasBloc, GorgiasState>(
              listener: (context, state) {
                log(
                  'GorgiasCard listener - State changed to: ${state.runtimeType}',
                );
                if (state is TicketStatsError) {
                  log('GorgiasCard listener - Error: ${state.message}');
                }
                if (state is TicketStatsLoaded) {
                  log(
                    'GorgiasCard listener - Stats loaded: Open=${state.stats.openTickets}, Closed=${state.stats.closedTickets}',
                  );
                }
              },
              builder: (context, state) {
                log(
                  'GorgiasCard builder - Building with state: ${state.runtimeType}',
                );
                if (state is TicketStatsLoaded || _hasCachedData) {
                  // Use live data if available, otherwise use cached
                  final openTickets = state is TicketStatsLoaded 
                      ? state.stats.openTickets 
                      : widget.cachedOpenTickets ?? 0;
                  final closedTickets = state is TicketStatsLoaded 
                      ? state.stats.closedTickets 
                      : widget.cachedClosedTickets ?? 0;
                  final totalTickets = state is TicketStatsLoaded 
                      ? (state.stats.totalTickets > 0 ? state.stats.totalTickets : 1)
                      : ((widget.cachedTotalTickets ?? 0) > 0 ? widget.cachedTotalTickets! : 1);
                  
                  final openProgress = openTickets / totalTickets;
                  final closedProgress = closedTickets / totalTickets;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(12),
                      // Open Tickets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppReusableText(
                            text: 'Open',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          AppReusableText(
                            text: openTickets.toString(),
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      const Gap(8),
                      CustomProgressBar(
                        progress: openProgress,
                        value: '',
                        color: Colors.orange,
                        backgroundColor: AppColors.backgroundDark,
                      ),
                      const Gap(16),
                      // Closed Tickets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppReusableText(
                            text: 'Closed',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          AppReusableText(
                            text: closedTickets.toString(),
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      const Gap(8),
                      CustomProgressBar(
                        progress: closedProgress,
                        value: '',
                        color: Colors.green,
                        backgroundColor: AppColors.backgroundDark,
                      ),
                    ],
                  );
                } else if (state is TicketStatsLoading && !_hasCachedData) {
                  // Only show loading if no cached data
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReusableText(
                        text: 'Loading...',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      const Gap(4),
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (state is TicketStatsError) {
                  log('TicketStatsError: ${state.message}');
                  // Schedule automatic retry
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scheduleRetry();
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppReusableText(
                            text: 'Error',
                            color: Colors.red,
                            fontSize: 10,
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const AppReusableText(
                        text: 'Retrying...',
                        color: Colors.red,
                        fontSize: 8,
                      ),
                    ],
                  );
                } else {
                  // Fallback to static data on initial state - auto load
                  log(
                    'GorgiasCard showing fallback data for state: ${state.runtimeType}',
                  );
                  // Schedule automatic loading for initial state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchTicketStatsWithRetry();
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Open Tickets
                      Row(
                        children: [
                          AppReusableText(
                            text: 'Open',
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      CustomProgressBar(
                        progress: 0.45,
                        value: '--',
                        color: Colors.orange.withOpacity(0.5),
                        backgroundColor: AppColors.backgroundDark,
                      ),
                      AppReusableText(
                        text: 'Closed',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      const Gap(2),
                      CustomProgressBar(
                        progress: 0.70,
                        value: '--',
                        color: Colors.green.withOpacity(0.5),
                        backgroundColor: AppColors.backgroundDark,
                      ),
                      const Gap(4),
                      AppReusableText(
                        text: 'Loading data...',
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
