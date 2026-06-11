import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_event.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_state.dart';
import 'package:woo_management_app/features/gorgias/models/gorgias_models.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/ticket_detail_screen.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';

import '../widgets/ticket_card_widget.dart';
import 'package:woo_management_app/widgets/highlight_container.dart';
import '../widgets/ticket_list_shimmer.dart';

class GorgiasDashboard extends StatefulWidget {
  final String? highlightTicketId;
  const GorgiasDashboard({super.key, this.highlightTicketId});

  @override
  State<GorgiasDashboard> createState() => _GorgiasDashboardState();
}

class _GorgiasDashboardState extends State<GorgiasDashboard> {
  TicketFilter _currentFilter = const TicketFilter();
  late GorgiasBloc _gorgiasBloc;
  bool _hasInitialized = false;
  bool _hasTriggeredFetchTickets = false;
  bool _isManualFilterChange = false;

  // ✅ Persist last loaded tickets to avoid flicker
  List<Ticket> _cachedTickets = [];
  int _cachedPage = 1;
  bool _cachedHasMore = false;

  // Deep-link highlight (from a tapped notification): scroll the matching
  // ticket into view and flash it, then clear. Mirrors the orders/shipments
  // pages.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _highlightKey = GlobalKey();
  String? _currentHighlightId;
  bool _scrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightTicketId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gorgiasBloc = context.read<GorgiasBloc>();

    if (!_hasInitialized) {
      _hasInitialized = true;

      _gorgiasBloc.add(const StartRealtimeUpdates());

      final currentState = _gorgiasBloc.state;
      if (currentState is! TicketsLoaded) {
        _gorgiasBloc.add(FetchTickets(filter: _currentFilter));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (!_gorgiasBloc.isClosed) {
      _gorgiasBloc.add(const StopRealtimeUpdates());
    }
    super.dispose();
  }

  /// Once tickets are on screen, scroll the highlighted one into view and clear
  /// the highlight after a few seconds. Runs at most once per deep link.
  void _triggerScrollAndHighlight() {
    if (_currentHighlightId == null || _scrolledToHighlight) return;
    _scrolledToHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_highlightKey.currentContext != null) {
          Scrollable.ensureVisible(
            _highlightKey.currentContext!,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubic,
            alignment: 0.35,
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _currentHighlightId = null);
            }
          });
        }
      });
    });
  }

  void _onFilterChanged(TicketFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _isManualFilterChange = true;
    });
    _gorgiasBloc.add(FetchTickets(filter: newFilter));
  }

  void _onRefresh() {
    setState(() {
      _hasTriggeredFetchTickets = false;
    });
    _gorgiasBloc.add(RefreshTickets(filter: _currentFilter));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(
        title: 'All Tickets',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _TicketFilterBar(
                  currentFilter: _currentFilter,
                  onFilterChanged: _onFilterChanged,
                ),
              ),
              Expanded(
                child: BlocBuilder<GorgiasBloc, GorgiasState>(
                  builder: (context, state) {
                    if (state is TicketsLoading) {
                      // ✅ If we already have cached tickets, show them instead of spinner
                      if (_cachedTickets.isNotEmpty) {
                        return _buildTicketsList(
                          _cachedTickets,
                          _cachedPage,
                          _cachedHasMore,
                        );
                      }
                      return const TicketListShimmer();
                    }

                    if (state is TicketStatsLoaded) {
                      if (!_hasTriggeredFetchTickets &&
                          _hasInitialized &&
                          !_isManualFilterChange) {
                        _hasTriggeredFetchTickets = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _gorgiasBloc.add(
                            FetchTickets(filter: _currentFilter),
                          );
                        });
                      }

                      // Agar tickets cache me hain to unhe hi show karte raho
                      if (_cachedTickets.isNotEmpty) {
                        return _buildTicketsList(
                          _cachedTickets,
                          _cachedPage,
                          _cachedHasMore,
                        );
                      }

                      return const TicketListShimmer();
                    }

                    if (state is TicketsError) {
                      if (_cachedTickets.isNotEmpty) {
                        // ✅ fallback to last cached tickets on error
                        return _buildTicketsList(
                          _cachedTickets,
                          _cachedPage,
                          _cachedHasMore,
                        );
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tickets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _onRefresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is TicketsLoaded) {
                      if (_isManualFilterChange) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _isManualFilterChange = false;
                          });
                        });
                      }

                      // ✅ Cache last loaded tickets
                      _cachedTickets = state.tickets;
                      _cachedPage = state.currentPage;
                      _cachedHasMore = state.hasMore;

                      return _buildTicketsList(
                        state.tickets,
                        state.currentPage,
                        state.hasMore,
                      );
                    }

                    // Default state
                    return const TicketListShimmer();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    List<Ticket> tickets,
    int currentPage,
    bool hasMore,
  ) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_activity_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No tickets found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentFilter.hasActiveFilters
                  ? 'Try adjusting your filters'
                  : 'No tickets available',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Schedule the scroll-to-highlight once the matching ticket is rendered.
    _triggerScrollAndHighlight();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: tickets.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == tickets.length) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  final nextPageFilter = _currentFilter.copyWith(
                    page: currentPage + 1,
                  );
                  _gorgiasBloc.add(FetchTickets(filter: nextPageFilter));
                },
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final ticket = tickets[index];
        final isHighlighted =
            _currentHighlightId != null &&
            ticket.id.toString() == _currentHighlightId;
        return HighlightContainer(
          key: isHighlighted ? _highlightKey : null,
          isHighlighted: isHighlighted,
          child: TicketCardWidget(
            ticket: ticket,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                ),
              ).then((_) {
                _gorgiasBloc.add(FetchTickets(filter: _currentFilter));
              });
            },
          ),
        );
      },
    );
  }
}

class _TicketFilterBar extends StatelessWidget {
  final TicketFilter currentFilter;
  final Function(TicketFilter) onFilterChanged;

  const _TicketFilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusFilters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Open', 'value': 'open'},
      {'label': 'Closed', 'value': 'closed'},
    ];

    final channelFilters = [];

    final allFilters = [...statusFilters, ...channelFilters];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = allFilters[index];
          final isStatusFilter = index < statusFilters.length;
          final isSelected =
              isStatusFilter
                  ? (currentFilter.status ?? 'all') == filter['value']
                  : currentFilter.channel == filter['value'];

          return GestureDetector(
            onTap: () {
              TicketFilter newFilter;
              if (isStatusFilter) {
                final status =
                    filter['value'] == 'all' ? null : filter['value'];
                newFilter = currentFilter.copyWith(
                  status: status,
                  page: 1, // Reset to first page
                );
              } else {
                final channel =
                    currentFilter.channel == filter['value']
                        ? null
                        : filter['value'];
                newFilter = currentFilter.copyWith(
                  channel: channel,
                  page: 1, // Reset to first page
                );
              }
              onFilterChanged(newFilter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border:
                    isSelected
                        ? Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1.5,
                        )
                        : Border.all(
                          color: AppColors.border.withOpacity(0.3),
                          width: 1,
                        ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
