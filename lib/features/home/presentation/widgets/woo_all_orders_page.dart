import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import 'package:woo_management_app/widgets/pagination_controls.dart';
import '../../../../core/services/woocommerce_service.dart';
import 'package:woo_management_app/widgets/highlight_container.dart';


class WooAllOrdersPage extends StatefulWidget {
  final String? highlightOrderId;
  const WooAllOrdersPage({super.key, this.highlightOrderId});

  @override
  State<WooAllOrdersPage> createState() => _WooAllOrdersPageState();
}

class _WooAllOrdersPageState extends State<WooAllOrdersPage> {
  static const int _perPage = 10;

  final WooCommerceService _wooService = WooCommerceService();
  final ScrollController _scrollController = ScrollController();

  /// Cache of previously loaded pages: page number → list of orders
  final Map<int, List<dynamic>> _pageCache = {};

  int _currentPage = 1;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _hasNextPage = true;
  String? _errorMessage;
  String? _currentHighlightId;
  bool _scrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    _currentHighlightId = widget.highlightOrderId;
    _fetchOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    // If page is already cached, use cached data instantly
    if (_pageCache.containsKey(_currentPage)) {
      setState(() {
        _orders = _pageCache[_currentPage]!;
        _hasNextPage = _orders.length >= _perPage;
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
      final orders = await _wooService.getOrders(
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        // Cache the fetched page
        _pageCache[_currentPage] = orders;
        setState(() {
          _orders = orders;
          _hasNextPage = orders.length >= _perPage;
          _isLoading = false;
        });
        _triggerScrollAndHighlight();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load orders';
          _isLoading = false;
        });
      }
    }
  }

  void _goToNextPage() {
    if (_hasNextPage && !_isLoading) {
      setState(() => _currentPage++);
      _fetchOrders();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoading) {
      setState(() => _currentPage--);
      _fetchOrders(); // Will hit cache instantly
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
      appBar: const SharedAppbar(title: 'All Orders'),
      body: Column(
        children: [
          // Content area — only this part shows shimmer during loading
          Expanded(
            child: _buildContent(),
          ),

          // Pagination controls pinned at the bottom (always visible after first load)
          if (_errorMessage == null && (_orders.isNotEmpty || _pageCache.isNotEmpty))
            PaginationControls(
              currentPage: _currentPage,
              hasNextPage: _hasNextPage,
              isLoading: _isLoading,
              onPrevious: _goToPreviousPage,
              onNext: _goToNextPage,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show shimmer in the list area when loading
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
              color: Colors.red.withValues(alpha: 0.7),
              size: 80,
            ),
            Gap(16),
            AppReusableText(
              text: _errorMessage!,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            Gap(8),
            AppReusableText(
              text: 'Please check your connection and try again',
              fontSize: 14,
              color: AppColors.greyB3.withValues(alpha: 0.5),
              textAlignment: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.shopping_cart_outline,
              color: AppColors.greyB3.withValues(alpha: 0.5),
              size: 80,
            ),
            Gap(16),
            AppReusableText(
              text: 'No orders found',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.greyB3.withValues(alpha: 0.7),
            ),
            Gap(8),
            AppReusableText(
              text: 'Orders will appear here when customers place them',
              fontSize: 14,
              color: AppColors.greyB3.withValues(alpha: 0.5),
              textAlignment: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final isHighlighted = _currentHighlightId != null &&
            order['id']?.toString() == _currentHighlightId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HighlightContainer(
            key: isHighlighted ? _highlightKey : null,
            isHighlighted: isHighlighted,
            child: _OrderItem(order: order),
          ),
        );
      },
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Gap(6),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          height: 16,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(6),
                        Container(
                          height: 20,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final dynamic order;

  const _OrderItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? 'N/A';
    final customerName = _getCustomerName();
    final total = order['total']?.toString() ?? '0';
    final status = order['status']?.toString() ?? 'unknown';
    final dateCreated = order['date_created']?.toString() ?? '';
    final lineItems = order['line_items'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with order ID and total
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReusableText(
                        text: 'Order #$orderId',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      Gap(2),
                      AppReusableText(
                        text: customerName,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppReusableText(
                      text: '\$$total',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AppReusableText(
                        text: status.toUpperCase(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Order details
            if (lineItems.isNotEmpty) ...[
              Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greyB3.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppReusableText(
                      text: 'Items (${lineItems.length})',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    const Gap(6),
                    ...lineItems.take(3).map((item) {
                      final name = item['name']?.toString() ?? 'Unknown Item';
                      final quantity = item['quantity']?.toString() ?? '1';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            AppReusableText(
                              text: '• $name',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            Spacer(),
                            AppReusableText(
                              text: 'x$quantity',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      );
                    }),
                    if (lineItems.length > 3)
                      AppReusableText(
                        text: '... and ${lineItems.length - 3} more items',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                  ],
                ),
              ),
            ],

            // Date
            if (dateCreated.isNotEmpty) ...[
              Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  Gap(4),
                  AppReusableText(
                    text: _formatDate(dateCreated),
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCustomerName() {
    final billing = order['billing'];
    if (billing != null) {
      final firstName = billing['first_name']?.toString() ?? '';
      final lastName = billing['last_name']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    return 'Guest Customer';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'refunded':
        return Colors.red;
      case 'failed':
        return Colors.red.shade700;
      default:
        return AppColors.greyB3;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'refunded':
        return Icons.money_off;
      case 'failed':
        return Icons.error_outline;
      default:
        return Iconsax.shopping_cart_outline;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
