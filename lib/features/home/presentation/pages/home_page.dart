import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/core/utils/app_logger.dart';
import 'package:woo_management_app/features/shipping/data/models/shipment_period.dart';
import 'package:woo_management_app/features/shipping/data/services/woocommerce_shipping_service.dart';
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
import '../../../analytics/models/revenue_period.dart';
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
  DashboardCacheData? _cachedData;
  bool _hasCache = false;
  bool _isFirstLoad = true;

  AnalyticsLoaded? _analyticsData;
  bool _analyticsLoaded = false;

  // Live shipping stats — updated directly from the bloc, independent of cache
  int? _shippingPending;
  int? _shippingInTransit;
  int? _shippingDelivered;
  int? _shippingTotal;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final cache = await DashboardCacheService.loadCache();

    if (mounted) {
      setState(() {
        _cachedData = cache;
        _hasCache = cache != null;
        _isFirstLoad = cache == null;
        // Seed live shipping from cache so the widget shows immediately
        _shippingPending = cache?.shippingPending;
        _shippingInTransit = cache?.shippingInTransit;
        _shippingDelivered = cache?.shippingDelivered;
        _shippingTotal = cache?.shippingTotal;
      });

      if (_hasCache) {
        final age = DateTime.now().difference(cache!.cachedAt);
        AppLog.cache('Dashboard',
            'Served from cache instantly (age: ${_formatAge(age)}) → refreshing in background');
      } else {
        AppLog.net('Dashboard', 'No cache → fetching fresh data (showing shimmer)');
      }

      if (!mounted) return;
      context.read<AnalyticsBloc>().add(const FetchAnalytics(0));
      context.read<GorgiasBloc>().add(const FetchTicketStats());
      context.read<ShippingBloc>().add(FetchShipmentStats(
            after: ShipmentPeriod.today.after,
            before: ShipmentPeriod.today.before,
          ));
    }
  }
  Future<void> _onRefresh() async {
    AppLog.refresh('Dashboard', 'Pull-to-refresh triggered → forcing fresh fetch');
    WooCommerceShippingService.clearStatsCache();
    if (!mounted) return;
    final analyticsBloc = context.read<AnalyticsBloc>();
    analyticsBloc.add(const FetchAnalytics(0));
    context.read<GorgiasBloc>().add(const FetchTicketStats());
    context.read<ShippingBloc>().add(const FetchShipmentStats());
    await analyticsBloc.stream
        .firstWhere((s) => s is AnalyticsLoaded || s is AnalyticsError)
        .timeout(const Duration(seconds: 35), onTimeout: () => analyticsBloc.state);
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return '${age.inSeconds}s';
    if (age.inHours < 1) return '${age.inMinutes}m';
    if (age.inDays < 1) return '${age.inHours}h';
    return '${age.inDays}d';
  }

  /// Show content as soon as analytics loads — gorgias/shipping render inline
  bool get _isAllDataReady {
    if (_isFirstLoad && !_hasCache) return _analyticsLoaded;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<AnalyticsBloc, AnalyticsState>(
              listenWhen: (previous, current) =>
                  current is AnalyticsLoaded || current is AnalyticsError,
              listener: (context, state) {
                if (state is AnalyticsLoaded) _handleAnalyticsUpdate(state);
              },
            ),
            BlocListener<GorgiasBloc, GorgiasState>(
              listenWhen: (previous, current) =>
                  current is TicketStatsLoaded || current is TicketStatsError,
              listener: (context, state) {
                if (state is TicketStatsLoaded) _handleGorgiasUpdate(state);
              },
            ),
            BlocListener<ShippingBloc, ShippingState>(
              listenWhen: (previous, current) =>
                  current is ShippingStatsLoaded ||
                  current is ShipmentsLoaded ||
                  current is ShippingError,
              listener: (context, state) {
                if (state is ShippingStatsLoaded) {
                  _handleShippingUpdate(state.stats);
                } else if (state is ShipmentsLoaded) {
                  _handleShippingUpdate(state.stats);
                }
              },
            ),
          ],
          child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            buildWhen: (previous, current) {
              if (current is AnalyticsLoaded) { return true; }
              if (current is AnalyticsError && !_hasCache) { return true; }
              if ((current is AnalyticsInitial || current is AnalyticsLoading) &&
                  !_hasCache) { return true; }
              return false;
            },
            builder: (context, analyticsState) {
              if (!_hasCache &&
                  !_analyticsLoaded &&
                  analyticsState is AnalyticsError) {
                return _buildErrorState();
              }
              if (!_isAllDataReady) { return const DashboardShimmer(); }

              String productsSoldCount = '0';
              String revenueCount = '\$0.00';
              String monthOrderCount = '0';
              String currentMonthLabel = '';
              List<dynamic> orders = [];

              if (analyticsState is AnalyticsLoaded) {
                currentMonthLabel = 'Today';
                productsSoldCount = analyticsState.itemsSoldToday.toString();
                // netSales is the current-day net revenue (tabIndex 0 window).
                revenueCount = _formatCompactCurrency(analyticsState.netSales);
                monthOrderCount = analyticsState.thisMonthOrderCount.toString();
                orders = analyticsState.orders.take(3).toList();
              } else if (_hasCache && _cachedData != null) {
                productsSoldCount = _cachedData!.itemsSoldToday.toString();
                revenueCount = _formatCompactCurrency(
                    _cachedData!.todayRevenue ?? _cachedData!.revenue);
                monthOrderCount = _cachedData!.thisMonthOrderCount.toString();
                currentMonthLabel = _cachedData!.currentMonthLabel;
                orders = _cachedData!.recentOrders.take(3).toList();
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                backgroundColor: isDark
                    ? const Color(0xFF1E1E2E)
                    : Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const UserAvatarWidget(
                      //   text: 'Profound Aminos',
                      //   userImage: 'assets/images/profound_icon.png',
                      // ),
                      // const Gap(32),
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
                              icon: Icons.tag_outlined,
                              title: 'Products Sold',
                              value: productsSoldCount,
                              subtitle: 'Today',
                              subtitleColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: StatCard(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.analytics,
                                  arguments: RevenuePeriod.today,
                                );
                              },
                              icon: Icons.attach_money,
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
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, RouteNames.ordersDetails);
                                },
                                icon: Icons.message_outlined,
                                title: 'WooCommerce \nOrders',
                                value: monthOrderCount,
                                subtitle: currentMonthLabel.isEmpty
                                    ? null
                                    : currentMonthLabel,
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
                      // Pass live shipping stats — always up-to-date regardless of cache timing
                      ShippingOverviewWidget(
                        pending: _shippingPending,
                        inTransit: _shippingInTransit,
                        delivered: _shippingDelivered,
                        total: _shippingTotal,
                      ),
                      const Gap(24),
                      CurrentOrdersWidget(cachedOrders: orders),
                      const Gap(24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleAnalyticsUpdate(AnalyticsLoaded state) {
    setState(() {
      _analyticsData = state;
      _analyticsLoaded = true;
    });
    _updateCache();
    developer.log(
      _isFirstLoad ? 'Analytics data loaded!' : 'Analytics updated!',
      name: 'Dashboard',
    );
    if (_isFirstLoad && mounted) setState(() => _isFirstLoad = false);
  }

  void _handleGorgiasUpdate(TicketStatsLoaded state) {
    final currentCache = _cachedData;
    if (currentCache == null) return;
    final updatedCache = DashboardCacheData(
      itemsSoldToday: currentCache.itemsSoldToday,
      revenue: currentCache.revenue,
      todayRevenue: currentCache.todayRevenue,
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

  void _handleShippingUpdate(dynamic stats) {
    // Always update live state — independent of whether cache exists yet
    setState(() {
      _shippingPending = stats.pending;
      _shippingInTransit = stats.inTransit;
      _shippingDelivered = stats.delivered;
      _shippingTotal = stats.total;
    });

    // Also persist to disk cache if analytics cache exists
    final currentCache = _cachedData;
    if (currentCache == null) return;
    final updatedCache = DashboardCacheData(
      itemsSoldToday: currentCache.itemsSoldToday,
      revenue: currentCache.revenue,
      todayRevenue: currentCache.todayRevenue,
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

  void _updateCache() {
    if (_analyticsData == null) return;
    final cacheData = DashboardCacheData(
      itemsSoldToday: _analyticsData!.itemsSoldToday,
      revenue: _analyticsData!.revenue,
      todayRevenue: _analyticsData!.netSales,
      thisMonthOrderCount: _analyticsData!.thisMonthOrderCount,
      totalOrderCount: _analyticsData!.totalOrderCount,
      currentMonthLabel: 'Today',
      recentOrders: _analyticsData!.orders.take(5).toList(),
      cachedAt: DateTime.now(),
      gorgiasOpenTickets: _cachedData?.gorgiasOpenTickets,
      gorgiasClosedTickets: _cachedData?.gorgiasClosedTickets,
      gorgiasTotalTickets: _cachedData?.gorgiasTotalTickets,
      shippingPending: _shippingPending,
      shippingInTransit: _shippingInTransit,
      shippingDelivered: _shippingDelivered,
      shippingTotal: _shippingTotal,
    );
    DashboardCacheService.saveCache(cacheData);
    setState(() {
      _cachedData = cacheData;
      _hasCache = true;
    });
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: AppColors.error, size: 48),
                    const Gap(16),
                    AppReusableText(
                      text: 'Couldn\'t load dashboard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    const Gap(8),
                    AppReusableText(
                      text: 'Check your connection and try again.',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(24),
                    ElevatedButton(
                      onPressed: () {
                        AppLog.refresh('Dashboard', 'Retry tapped → re-fetching');
                        context
                            .read<AnalyticsBloc>()
                            .add(const FetchAnalytics(0));
                        context.read<GorgiasBloc>().add(const FetchTicketStats());
                        context
                            .read<ShippingBloc>()
                            .add(const FetchShipmentStats());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}
