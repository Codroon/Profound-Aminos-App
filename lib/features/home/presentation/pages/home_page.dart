import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../widgets/dashboard_shimmer.dart';
import '../widgets/gorgias_card.dart';
import '../widgets/shipping_overview_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/current_orders_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_event.dart';
import '../../../analytics/bloc/analytics_state.dart';
import '../../../gorgias/bloc/gorgias_bloc.dart';
import '../../../gorgias/bloc/gorgias_event.dart';
import '../../../gorgias/bloc/gorgias_state.dart';
import '../../../shipping/bloc/shipping_bloc.dart';
import '../../../shipping/bloc/shipping_event.dart';
import '../../../shipping/bloc/shipping_state.dart';
import '../../services/dashboard_cache_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Cached data that can be shown instantly
  DashboardCacheData? _cachedData;
  bool _hasCache = false;
  bool _isFirstLoad = true;
  
  // Track data loading states
  AnalyticsLoaded? _analyticsData;
  bool _analyticsLoaded = false;
  bool _gorgiasLoaded = false;
  bool _shippingLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  /// Load cached data and determine if we should show shimmer or cached data
  Future<void> _loadCachedData() async {
    final cache = await DashboardCacheService.loadCache();
    
    if (mounted) {
      setState(() {
        _cachedData = cache;
        _hasCache = cache != null;
        _isFirstLoad = cache == null;
      });

      // Always fetch fresh data in background
      developer.log(
        _hasCache 
          ? 'Cache loaded, triggering background refresh' 
          : 'No cache found, fetching fresh data',
        name: 'Dashboard'
      );
      
      if (!mounted) return;
      
      // Fetch analytics, gorgias, and shipping data
      context.read<AnalyticsBloc>().add(const FetchAnalytics(0));
      context.read<GorgiasBloc>().add(const FetchTicketStats());
      context.read<ShippingBloc>().add(const FetchShipmentStats());
    }
  }

  /// Check if all data is ready to show
  bool get _isAllDataReady {
    if (_isFirstLoad && !_hasCache) {
      // First time with no cache - wait for analytics, gorgias, and shipping
      return _analyticsLoaded && _gorgiasLoaded && _shippingLoaded;
    }
    // Have cache - show immediately
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            // Analytics Listener
            BlocListener<AnalyticsBloc, AnalyticsState>(
              listenWhen: (previous, current) {
                return current is AnalyticsLoaded || current is AnalyticsError;
              },
              listener: (context, state) {
                if (state is AnalyticsLoaded) {
                  _handleAnalyticsUpdate(state);
                }
              },
            ),
            // Gorgias Listener  
            BlocListener<GorgiasBloc, GorgiasState>(
              listenWhen: (previous, current) {
                return current is TicketStatsLoaded || current is TicketStatsError;
              },
              listener: (context, state) {
                if (state is TicketStatsLoaded) {
                  _handleGorgiasUpdate(state);
                } else if (state is TicketStatsError) {
                  // Even on error, mark as "loaded" to not block UI
                  setState(() => _gorgiasLoaded = true);
                }
              },
            ),
            // Shipping Listener
            BlocListener<ShippingBloc, ShippingState>(
              listenWhen: (previous, current) {
                return current is ShippingStatsLoaded || current is ShipmentsLoaded || current is ShippingError;
              },
              listener: (context, state) {
                if (state is ShippingStatsLoaded) {
                  _handleShippingUpdate(state.stats);
                } else if (state is ShipmentsLoaded) {
                  _handleShippingUpdate(state.stats);
                } else if (state is ShippingError) {
                  // Even on error, mark as "loaded" to not block UI
                  setState(() => _shippingLoaded = true);
                }
              },
            ),
          ],
          child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            buildWhen: (previous, current) {
              // Only rebuild on meaningful state changes
              if (current is AnalyticsLoaded) return true;
              if (current is AnalyticsError && !_hasCache) return true;
              if ((current is AnalyticsInitial || current is AnalyticsLoading) && !_hasCache) return true;
              return false;
            },
            builder: (context, analyticsState) {
              // Show shimmer until ALL data is ready (on first load with no cache)
              if (!_isAllDataReady) {
                return const DashboardShimmer();
              }

              // Get analytics values
              String productCount = '0';
              String revenueCount = '\$0.00';
              String monthOrderCount = '0';
              String currentMonthLabel = '';
              List<dynamic> orders = [];

              if (analyticsState is AnalyticsLoaded) {
                final now = DateTime.now();
                const monthNames = [
                  'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December',
                ];
                currentMonthLabel = '${monthNames[now.month - 1]} ${now.year}';
                productCount = analyticsState.totalProductCount.toString();
                revenueCount = _formatCompactCurrency(analyticsState.revenue);
                monthOrderCount = analyticsState.thisMonthOrderCount.toString();
                orders = analyticsState.orders.take(3).toList();
              } else if (_hasCache && _cachedData != null) {
                productCount = _cachedData!.totalProductCount.toString();
                revenueCount = _formatCompactCurrency(_cachedData!.revenue);
                monthOrderCount = _cachedData!.thisMonthOrderCount.toString();
                currentMonthLabel = _cachedData!.currentMonthLabel;
                orders = _cachedData!.recentOrders.take(3).toList();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UserAvatarWidget(
                      text: 'Profound Aminos',
                      userImage: 'assets/images/profound_icon.png',
                    ),
                    const Gap(32),
                    AppReusableText(
                      text: 'Dashboard',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            onTap: () {
                              Navigator.pushNamed(context, RouteNames.wooProduct);
                            },
                            icon: Iconsax.tag_outline,
                            title: 'Products',
                            value: productCount,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: StatCard(
                            onTap: () {
                              Navigator.pushNamed(context, RouteNames.analytics);
                            },
                            icon: Iconsax.dollar_circle_bold,
                            title: 'Revenue',
                            value: revenueCount,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.message_outline,
                              title: 'WooCommerce \nOrders',
                              value: monthOrderCount,
                              subtitle: currentMonthLabel.isEmpty ? null : currentMonthLabel,
                              subtitleColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: GorgiasCard(
                              cachedOpenTickets: _cachedData?.gorgiasOpenTickets,
                              cachedClosedTickets: _cachedData?.gorgiasClosedTickets,
                              cachedTotalTickets: _cachedData?.gorgiasTotalTickets,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),
                    CurrentOrdersWidget(cachedOrders: orders),
                    const Gap(24),
                    ShippingOverviewWidget(
                      pending: _cachedData?.shippingPending,
                      inTransit: _cachedData?.shippingInTransit,
                      delivered: _cachedData?.shippingDelivered,
                      total: _cachedData?.shippingTotal,
                    ),
                    const Gap(24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Handle analytics data update
  void _handleAnalyticsUpdate(AnalyticsLoaded state) {
    setState(() {
      _analyticsData = state;
      _analyticsLoaded = true;
    });

    // Update cache with analytics data
    _updateCache();

    // Log
    if (_isFirstLoad) {
      developer.log('Analytics data loaded!', name: 'Dashboard');
    } else {
      developer.log('data updated!', name: 'Dashboard');
    }

    // Mark first load complete
    if (_isFirstLoad && mounted) {
      setState(() => _isFirstLoad = false);
    }
  }

  /// Handle gorgias data update
  void _handleGorgiasUpdate(TicketStatsLoaded state) {
    setState(() => _gorgiasLoaded = true);

    // Update cache with gorgias data
    final currentCache = _cachedData;
    if (currentCache != null) {
      final updatedCache = DashboardCacheData(
        totalProductCount: currentCache.totalProductCount,
        revenue: currentCache.revenue,
        thisMonthOrderCount: currentCache.thisMonthOrderCount,
        totalOrderCount: currentCache.totalOrderCount,
        currentMonthLabel: currentCache.currentMonthLabel,
        recentOrders: currentCache.recentOrders,
        cachedAt: DateTime.now(),
        gorgiasOpenTickets: state.stats.openTickets,
        gorgiasClosedTickets: state.stats.closedTickets,
        gorgiasTotalTickets: state.stats.totalTickets,
        shippingPending: currentCache.shippingPending,
        shippingInTransit: currentCache.shippingInTransit,
        shippingDelivered: currentCache.shippingDelivered,
        shippingTotal: currentCache.shippingTotal,
      );
      DashboardCacheService.saveCache(updatedCache);
      setState(() => _cachedData = updatedCache);
    }
  }

  /// Handle shipping data update
  void _handleShippingUpdate(dynamic stats) {
    setState(() => _shippingLoaded = true);

    // Update cache with shipping data
    final currentCache = _cachedData;
    if (currentCache != null) {
      final updatedCache = DashboardCacheData(
        totalProductCount: currentCache.totalProductCount,
        revenue: currentCache.revenue,
        thisMonthOrderCount: currentCache.thisMonthOrderCount,
        totalOrderCount: currentCache.totalOrderCount,
        currentMonthLabel: currentCache.currentMonthLabel,
        recentOrders: currentCache.recentOrders,
        cachedAt: DateTime.now(),
        gorgiasOpenTickets: currentCache.gorgiasOpenTickets,
        gorgiasClosedTickets: currentCache.gorgiasClosedTickets,
        gorgiasTotalTickets: currentCache.gorgiasTotalTickets,
        shippingPending: stats.pending,
        shippingInTransit: stats.inTransit,
        shippingDelivered: stats.delivered,
        shippingTotal: stats.total,
      );
      DashboardCacheService.saveCache(updatedCache);
      setState(() => _cachedData = updatedCache);
    }
  }

  /// Update cache with current data
  void _updateCache() {
    if (_analyticsData == null) return;
    
    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    
    final cacheData = DashboardCacheData(
      totalProductCount: _analyticsData!.totalProductCount,
      revenue: _analyticsData!.revenue,
      thisMonthOrderCount: _analyticsData!.thisMonthOrderCount,
      totalOrderCount: _analyticsData!.totalOrderCount,
      currentMonthLabel: '${monthNames[now.month - 1]} ${now.year}',
      recentOrders: _analyticsData!.orders.take(5).toList(),
      cachedAt: DateTime.now(),
      gorgiasOpenTickets: _cachedData?.gorgiasOpenTickets,
      gorgiasClosedTickets: _cachedData?.gorgiasClosedTickets,
      gorgiasTotalTickets: _cachedData?.gorgiasTotalTickets,
      shippingPending: _cachedData?.shippingPending,
      shippingInTransit: _cachedData?.shippingInTransit,
      shippingDelivered: _cachedData?.shippingDelivered,
      shippingTotal: _cachedData?.shippingTotal,
    );

    DashboardCacheService.saveCache(cacheData);
    setState(() {
      _cachedData = cacheData;
      _hasCache = true;
    });
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}
