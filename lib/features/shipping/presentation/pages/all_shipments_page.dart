import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/highlight_container.dart';


import '../../data/models/shipment_order.dart';
import '../../data/models/shipment_period.dart';
import '../../data/services/woocommerce_shipping_service.dart';

class AllShipmentsPage extends StatefulWidget {
  final String? highlightShipmentId;

  /// Optional time filter carried over from the shipping dashboard. When set,
  /// only shipments within this period are listed. Null shows all shipments.
  final ShipmentPeriod? period;

  const AllShipmentsPage({super.key, this.highlightShipmentId, this.period});

  @override
  State<AllShipmentsPage> createState() => _AllShipmentsPageState();
}

class _AllShipmentsPageState extends State<AllShipmentsPage> {
  /// How many shipments are pulled per page as you scroll.
  static const int _perPage = 20;

  final ScrollController _scrollController = ScrollController();

  final List<ShipmentOrder> _shipments = [];
  int _nextPage = 1;
  bool _isLoading = true; // first-page load (shows shimmer)
  bool _isLoadingMore = false; // appending more while scrolling
  bool _hasMore = true;
  String? _errorMessage;
  String? _currentHighlightId;
  bool _scrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightShipmentId;
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load the next page when the user nears the bottom.
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMore();
    }
  }

  /// (Re)load from the first page — used on initial load and pull-to-refresh.
  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _shipments.clear();
      _nextPage = 1;
      _hasMore = true;
    });

    try {
      final batch = await WooCommerceShippingService.fetchShipments(
        page: 1,
        perPage: _perPage,
        after: widget.period?.after,
        before: widget.period?.before,
      );
      if (!mounted) return;
      setState(() {
        _shipments.addAll(batch);
        _nextPage = 2;
        _hasMore = batch.length >= _perPage;
        _isLoading = false;
      });
      _triggerScrollAndHighlight();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shipments';
          _isLoading = false;
        });
      }
    }
  }

  /// Append the next page. A failure here just stops further loading; the
  /// already-loaded shipments stay on screen.
  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final batch = await WooCommerceShippingService.fetchShipments(
        page: _nextPage,
        perPage: _perPage,
        after: widget.period?.after,
        before: widget.period?.before,
      );
      if (!mounted) return;
      setState(() {
        _shipments.addAll(batch);
        _nextPage += 1;
        _hasMore = batch.length >= _perPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false; // stop hammering a failing endpoint
        });
      }
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
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(8),
                  AppReusableText(
                    text: widget.period == null
                        ? 'All Shipments'
                        : 'All Shipments • ${widget.period!.label}',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                    ),
                    onPressed: _loadFirstPage,
                  ),
                ],
              ),
            ),

            // Shipment List — only this area shows shimmer
            Expanded(
              child: _buildContent(),
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
              onPressed: _loadFirstPage,
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
              Icons.inventory_2_outlined,
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
      onRefresh: _loadFirstPage,
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // One extra row for the bottom loader / end-of-list spacer.
        itemCount: _shipments.length + 1,
        itemBuilder: (context, index) {
          if (index >= _shipments.length) {
            return _buildBottomLoader();
          }
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

  Widget _buildBottomLoader() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore && _shipments.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: AppReusableText(
            text: 'No more shipments',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
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
                  _buildSectionTitleWithIcon(Icons.person_outline, 'CUSTOMER'),
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
                  _buildSectionTitleWithIcon(Icons.inventory_2_outlined, 'PRODUCTS'),
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
                                  Icons.inventory_2_outlined,
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
                  _buildSectionTitleWithIcon(Icons.receipt_long, 'TOTALS'),
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
                  _buildSectionTitleWithIcon(Icons.local_shipping, 'SHIPMENT INFO'),
                  const Gap(12),
                  _buildInfoCard(
                    child: _buildShipmentInfoRow(
                      'Carrier',
                      shipment.carrier ?? shipment.service ?? '-',
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
                Icon(Icons.open_in_new, color: AppColors.primary, size: 14),
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
