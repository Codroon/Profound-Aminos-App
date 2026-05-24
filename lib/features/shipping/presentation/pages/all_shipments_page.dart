import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/pagination_controls.dart';
import 'package:woo_management_app/widgets/highlight_container.dart';


import '../../data/models/shipment_order.dart';
import '../../data/services/woocommerce_shipping_service.dart';

class AllShipmentsPage extends StatefulWidget {
  final String? highlightShipmentId;
  const AllShipmentsPage({super.key, this.highlightShipmentId});

  @override
  State<AllShipmentsPage> createState() => _AllShipmentsPageState();
}

class _AllShipmentsPageState extends State<AllShipmentsPage> {
  static const int _perPage = 10;

  final ScrollController _scrollController = ScrollController();

  /// Cache of previously loaded pages: page number → list of shipments
  final Map<int, List<ShipmentOrder>> _pageCache = {};

  int _currentPage = 1;
  List<ShipmentOrder> _shipments = [];
  bool _isLoading = true;
  bool _hasNextPage = true;
  String? _errorMessage;
  String? _currentHighlightId;
  bool _scrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightShipmentId;
    _fetchShipments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchShipments() async {
    // If page is already cached, use cached data instantly
    if (_pageCache.containsKey(_currentPage)) {
      setState(() {
        _shipments = _pageCache[_currentPage]!;
        _hasNextPage = _shipments.length >= _perPage;
        _isLoading = false;
        _errorMessage = null;
      });
      _triggerScrollAndHighlight();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shipments = await WooCommerceShippingService.fetchShipments(
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        // Cache the fetched page
        _pageCache[_currentPage] = shipments;
        setState(() {
          _shipments = shipments;
          _hasNextPage = shipments.length >= _perPage;
          _isLoading = false;
        });
        _triggerScrollAndHighlight();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shipments';
          _isLoading = false;
        });
      }
    }
  }

  void _goToNextPage() {
    if (_hasNextPage && !_isLoading) {
      setState(() => _currentPage++);
      _fetchShipments();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoading) {
      setState(() => _currentPage--);
      _fetchShipments(); // Will hit cache instantly
    }
  }

  final GlobalKey _highlightKey = GlobalKey();

  void _triggerScrollAndHighlight() {
    if (_currentHighlightId != null && !_scrolledToHighlight) {
      _scrolledToHighlight = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a slight delay for list viewport rendering
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_highlightKey.currentContext != null) {
            Scrollable.ensureVisible(
              _highlightKey.currentContext!,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCubic,
              alignment: 0.35, // Centers the item beautifully in the visible viewport
            );
            // Auto-clear highlight state after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _currentHighlightId = null;
                });
              }
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Iconsax.arrow_left_outline,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(8),
                  AppReusableText(
                    text: 'All Shipments',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Iconsax.refresh_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      // Clear cache and re-fetch current page
                      _pageCache.clear();
                      _fetchShipments();
                    },
                  ),
                ],
              ),
            ),

            // Shipment List — only this area shows shimmer
            Expanded(
              child: _buildContent(),
            ),

            // Pagination controls pinned at the bottom (always visible after first load)
            if (_errorMessage == null && (_shipments.isNotEmpty || _pageCache.isNotEmpty))
              PaginationControls(
                currentPage: _currentPage,
                hasNextPage: _hasNextPage,
                isLoading: _isLoading,
                onPrevious: _goToPreviousPage,
                onNext: _goToNextPage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const Gap(16),
            AppReusableText(
              text: 'Failed to load shipments',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            const Gap(8),
            ElevatedButton(
              onPressed: _fetchShipments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.box_outline,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 64,
            ),
            const Gap(16),
            AppReusableText(
              text: 'No shipments found',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _pageCache.remove(_currentPage);
        await _fetchShipments();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _shipments.length,
        itemBuilder: (context, index) {
          final shipment = _shipments[index];
          final isHighlighted = _currentHighlightId != null &&
              shipment.id.toString() == _currentHighlightId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HighlightContainer(
              key: isHighlighted ? _highlightKey : null,
              isHighlighted: isHighlighted,
              child: _buildShipmentListItem(shipment),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.backgroundDark.withValues(alpha: 0.5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 22,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipmentListItem(ShipmentOrder shipment) {
    return GestureDetector(
      onTap: () => _showShipmentDetail(shipment),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppReusableText(
                  text: shipment.displayId,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                const Spacer(),
                _buildStatusBadge(shipment.status),
              ],
            ),
            const Gap(6),
            Row(
  children: [
    Expanded(
      child: AppReusableText(
        text:
            '${shipment.customerName} • ${shipment.toAddress.city}, ${shipment.toAddress.state}',
        fontSize: 13,
        color: AppColors.textSecondary,
        maxLines: 1,
      ),
    ),
    const Gap(8),
    Expanded(
      child: AppReusableText(
        text:
            '${shipment.service ?? '-'} • \$${shipment.shippingCost.toStringAsFixed(2)}',
        fontSize: 12,
        color: AppColors.textSecondary,
        maxLines: 1,
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'in_transit':
        color = Colors.blue;
        label = 'In Transit';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Fulfilled';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppReusableText(
        text: label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  void _showShipmentDetail(ShipmentOrder shipment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => _ShipmentDetailBottomSheet(
                  shipment: shipment,
                  scrollController: scrollController,
                ),
          ),
    );
  }
}

class _ShipmentDetailBottomSheet extends StatelessWidget {
  final ShipmentOrder shipment;
  final ScrollController scrollController;

  const _ShipmentDetailBottomSheet({
    required this.shipment,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with order ID and status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AppReusableText(
                  text: shipment.displayId,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(6),
                      AppReusableText(
                        text: _getStatusLabel(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppReusableText(
                text: _formatDateTime(shipment.dateCreated),
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Gap(20),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Section
                  _buildSectionTitleWithIcon(Iconsax.user_outline, 'CUSTOMER'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppReusableText(
                          text: shipment.customerName.isNotEmpty ? shipment.customerName : '-',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        const Gap(4),
                        AppReusableText(
                          text: shipment.toAddress.street1.isNotEmpty ? shipment.toAddress.street1 : '-',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        AppReusableText(
                          text: '${shipment.toAddress.city}, ${shipment.toAddress.state} ${shipment.toAddress.postalCode}',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Products Section
                  _buildSectionTitleWithIcon(Iconsax.box_outline, 'PRODUCTS'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      children: shipment.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.box_outline,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppReusableText(
                                      text: item.name,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    AppReusableText(
                                      text: 'Qty: ${item.quantity}',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                              AppReusableText(
                                text: '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Gap(20),

                  // Totals Section
                  _buildSectionTitleWithIcon(Iconsax.receipt_outline, 'TOTALS'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', '\$${_calculateSubtotal().toStringAsFixed(2)}'),
                        const Gap(8),
                        _buildTotalRow('Shipping', '\$${shipment.shippingCost.toStringAsFixed(2)}'),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: _buildTotalRow(
                            'Total',
                            '\$${shipment.total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Shipment Info Section
                  _buildSectionTitleWithIcon(Iconsax.truck_fast_outline, 'SHIPMENT INFO'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      children: [
                        _buildShipmentInfoRow('Carrier', shipment.carrier ?? '-'),
                        const Gap(12),
                        _buildShipmentInfoRow('Tracking Number', shipment.trackingNumber ?? '-', isLink: true),
                        const Gap(12),
                        _buildShipmentInfoRow('Date Shipped', shipment.dateShipped != null ? _formatDate(shipment.dateShipped!) : '-'),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Track Button
                  if (shipment.hasTracking)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Open carrier tracking website
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Track with ${shipment.carrier ?? 'Carrier'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (shipment.status) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (shipment.status) {
      case 'pending':
        return 'Pending';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Fulfilled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  double _calculateSubtotal() {
    return shipment.items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildSectionTitleWithIcon(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const Gap(8),
        AppReusableText(
          text: title,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppReusableText(
          text: label,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        AppReusableText(
          text: value,
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: isTotal ? AppColors.primary : AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildShipmentInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppReusableText(
          text: label,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        isLink && value != '-'
          ? Row(
              children: [
                AppReusableText(
                  text: value,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                const Gap(4),
                Icon(Iconsax.export_3_outline, color: AppColors.primary, size: 14),
              ],
            )
          : AppReusableText(
              text: value,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
      ],
    );
  }
}
