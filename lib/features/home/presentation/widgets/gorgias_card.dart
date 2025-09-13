import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../core/routes/routes_name.dart';
import '../../../../widgets/custom_progress_bar.dart';
import '../../../gorgias/bloc/gorgias_bloc.dart';
import '../../../gorgias/bloc/gorgias_event.dart';
import '../../../gorgias/bloc/gorgias_state.dart';

class GorgiasCard extends StatefulWidget {
  const GorgiasCard({super.key});

  @override
  State<GorgiasCard> createState() => _GorgiasCardState();
}

class _GorgiasCardState extends State<GorgiasCard> {
  bool _hasInitialized = false;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Always try to fetch ticket stats on first load
      _fetchTicketStatsWithRetry();
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
                const Icon(
                  Iconsax.element_4_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                AppReusableText(
                  text: 'Gorgias',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
                if (state is TicketStatsLoaded) {
                  final stats = state.stats;
                  final totalTickets =
                      stats.totalTickets > 0 ? stats.totalTickets : 1;
                  final openProgress = stats.openTickets / totalTickets;
                  final closedProgress = stats.closedTickets / totalTickets;
                  log(
                    "🔓Open Tickets: ${stats.openTickets}, 🔐Closed Tickets: ${stats.closedTickets},🗿 Total Tickets: $totalTickets",
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Open Tickets
                      const Text(
                        'Open',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      CustomProgressBar(
                        progress: openProgress,
                        value: stats.openTickets.toString(),
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      const Text(
                        'Closed',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const Gap(2),
                      CustomProgressBar(
                        progress: closedProgress,
                        value: stats.closedTickets.toString(),
                        color: const Color(0xFF00ADB5),
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  );
                } else if (state is TicketStatsLoading) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      Gap(4),
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
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
                          const Text(
                            'Error',
                            style: TextStyle(color: Colors.red, fontSize: 10),
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
                      const Text(
                        'Retrying...',
                        style: TextStyle(color: Colors.red, fontSize: 8),
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
                          const Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      CustomProgressBar(
                        progress: 0.45,
                        value: '--',
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      const Text(
                        'Closed',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const Gap(2),
                      CustomProgressBar(
                        progress: 0.70,
                        value: '--',
                        color: const Color(0xFF00ADB5),
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      const Gap(4),
                      const Text(
                        'Loading data...',
                        style: TextStyle(color: Colors.white54, fontSize: 8),
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
