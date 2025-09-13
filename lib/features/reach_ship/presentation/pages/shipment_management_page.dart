import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../bloc/reach_ship_bloc.dart';
import '../../bloc/reach_ship_event.dart';
import '../../bloc/reach_ship_state.dart';
import '../../models/shipment.dart';
import '../widgets/shipment_list_item.dart';
import '../widgets/shipment_filter_sheet.dart';
import 'create_shipment_page.dart';
import 'shipment_tracking_page.dart';

class ShipmentManagementPage extends StatefulWidget {
  const ShipmentManagementPage({super.key});

  @override
  State<ShipmentManagementPage> createState() => _ShipmentManagementPageState();
}

class _ShipmentManagementPageState extends State<ShipmentManagementPage>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Shipment> _allShipments = [];
  List<Shipment> _filteredShipments = [];
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: SharedAppbar(
        title: 'Manage Shipments',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateShipment(),
          ),
        ],
      ),
      body: BlocListener<ReachShipBloc, ReachShipState>(
        listener: (context, state) {
          if (state is ShipmentsLoaded) {
            setState(() {
              _allShipments = state.shipments;
              _applyFilters();
            });
          } else if (state is ShipmentDeleted) {
            _loadShipments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shipment deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ReachShipError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            log('Error loading shipments: ${state.message}');
          }
        },
        child: Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilterSection(),

            // Status Tabs
            _buildStatusTabs(),

            // Shipments List
            Expanded(child: _buildShipmentsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateShipment(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  hintText: 'Search by tracking number, recipient...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              Container(
                decoration: BoxDecoration(
                  color:
                      _activeFilters.isNotEmpty
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _activeFilters.isNotEmpty
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color:
                        _activeFilters.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  onPressed: () => _showFilterSheet(),
                ),
              ),
            ],
          ),

          // Active Filters
          if (_activeFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _activeFilters.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeFilter(entry.key),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        dividerColor: Colors.transparent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        physics: const BouncingScrollPhysics(),
        isScrollable: true,
        onTap: (index) => _filterByStatus(index),
        tabs: [
          Tab(child: _buildTabWithCount('All', _allShipments.length)),
          Tab(
            child: _buildTabWithCount(
              'Pending',
              _getShipmentCountByStatus(['pending', 'label_created']),
            ),
          ),
          Tab(
            child: _buildTabWithCount(
              'In Transit',
              _getShipmentCountByStatus(['in_transit', 'out_for_delivery']),
            ),
          ),
          Tab(
            child: _buildTabWithCount(
              'Delivered',
              _getShipmentCountByStatus(['delivered']),
            ),
          ),
          Tab(
            child: _buildTabWithCount(
              'Issues',
              _getShipmentCountByStatus(['exception', 'failed', 'returned']),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithCount(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShipmentsList() {
    return BlocBuilder<ReachShipBloc, ReachShipState>(
      builder: (context, state) {
        if (state is ReachShipLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Loading shipments...', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        if (_filteredShipments.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _loadShipments(),
          color: AppColors.primary,
          backgroundColor: AppColors.cardDark,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredShipments.length,
            itemBuilder: (context, index) {
              final shipment = _filteredShipments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShipmentListItem(
                  shipment: shipment,
                  onTap: () => _navigateToTracking(shipment),
                  onEdit: () => _editShipment(shipment),
                  onDelete: () => _showDeleteDialog(shipment),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                  ? Icons.search_off
                  : Icons.local_shipping_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                  ? 'No shipments found'
                  : 'No shipments yet',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Create your first shipment to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty && _activeFilters.isEmpty)
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: CustomButton(
                  text: 'Create Shipment',
                  onPressed: () => _navigateToCreateShipment(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _loadShipments() {
    context.read<ReachShipBloc>().add(const GetShipmentsEvent());
  }

  void _applyFilters() {
    setState(() {
      _filteredShipments =
          _allShipments.where((shipment) {
            // Search filter
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesSearch =
                  (shipment.trackingNumber?.toLowerCase().contains(query) ??
                      false) ||
                  (shipment.toAddress.name?.toLowerCase().contains(query) ??
                      false) ||
                  (shipment.toAddress.company?.toLowerCase().contains(query) ??
                      false) ||
                  (shipment.selectedRate.carrierName.toLowerCase().contains(
                    query,
                  ));

              if (!matchesSearch) return false;
            }

            // Status filter
            if (_activeFilters.containsKey('status')) {
              if (shipment.status != _activeFilters['status']) return false;
            }

            // Carrier filter
            if (_activeFilters.containsKey('carrier')) {
              if (shipment.selectedRate.carrierName !=
                  _activeFilters['carrier'])
                return false;
            }

            // Date range filter
            if (_activeFilters.containsKey('dateRange')) {
              final dateRange =
                  _activeFilters['dateRange'] as Map<String, DateTime>;
              final shipmentDate = shipment.createdAt;
              if (shipmentDate.isBefore(dateRange['start']!) ||
                  shipmentDate.isAfter(dateRange['end']!)) {
                return false;
              }
            }

            return true;
          }).toList();
    });
  }

  void _filterByStatus(int tabIndex) {
    setState(() {
      _activeFilters.remove('status');

      switch (tabIndex) {
        case 0: // All
          break;
        case 1: // Pending
          _activeFilters['status'] = 'pending';
          break;
        case 2: // In Transit
          _activeFilters['status'] = 'in_transit';
          break;
        case 3: // Delivered
          _activeFilters['status'] = 'delivered';
          break;
        case 4: // Issues
          _activeFilters['status'] = 'exception';
          break;
      }
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ShipmentFilterSheet(
            activeFilters: _activeFilters,
            onFiltersChanged: (filters) {
              setState(() {
                _activeFilters = filters;
              });
              _applyFilters();
            },
          ),
    );
  }

  void _removeFilter(String key) {
    setState(() {
      _activeFilters.remove(key);
    });
    _applyFilters();
  }

  int _getShipmentCountByStatus(List<String> statuses) {
    return _allShipments
        .where(
          (shipment) => statuses.contains(shipment.status.name.toLowerCase()),
        )
        .length;
  }

  void _navigateToCreateShipment() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const CreateShipmentPage()),
        )
        .then((_) => _loadShipments());
  }

  void _navigateToTracking(Shipment shipment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShipmentTrackingPage(shipment: shipment),
      ),
    );
  }

  void _editShipment(Shipment shipment) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CreateShipmentPage(editingShipment: shipment),
          ),
        )
        .then((_) => _loadShipments());
  }

  void _showDeleteDialog(Shipment shipment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Text('Delete Shipment', style: AppTextStyles.h4),
            content: Text(
              'Are you sure you want to delete this shipment?\n\nTracking: ${shipment.trackingNumber ?? 'N/A'}',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<ReachShipBloc>().add(
                    DeleteShipmentEvent(shipmentId: shipment.id),
                  );
                },
                child: Text(
                  'Delete',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
