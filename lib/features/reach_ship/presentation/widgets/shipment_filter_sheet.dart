import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_button.dart';

class ShipmentFilterSheet extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  
  const ShipmentFilterSheet({
    super.key,
    required this.activeFilters,
    required this.onFiltersChanged,
  });

  @override
  State<ShipmentFilterSheet> createState() => _ShipmentFilterSheetState();
}

class _ShipmentFilterSheetState extends State<ShipmentFilterSheet> {
  late Map<String, dynamic> _filters;
  
  final List<String> _statusOptions = [
    'pending',
    'label_created',
    'ready_for_pickup',
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
    'exception',
    'failed',
    'returned',
  ];
  
  final List<String> _carrierOptions = [
    'UPS',
    'FedEx',
    'USPS',
    'DHL',
    'OnTrac',
    'LaserShip',
  ];
  
  final List<String> _serviceOptions = [
    'Ground',
    'Express',
    'Overnight',
    'Two Day',
    'Priority',
    'Standard',
  ];
  
  DateTimeRange? _selectedDateRange;
  
  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.activeFilters);
    
    if (_filters.containsKey('dateRange')) {
      final dateRange = _filters['dateRange'] as Map<String, DateTime>;
      _selectedDateRange = DateTimeRange(
        start: dateRange['start']!,
        end: dateRange['end']!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Shipments',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Filters Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _buildStatusFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Carrier Filter
                  _buildFilterSection(
                    'Carrier',
                    _buildCarrierFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Service Type Filter
                  _buildFilterSection(
                    'Service Type',
                    _buildServiceFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date Range Filter
                  _buildFilterSection(
                    'Date Range',
                    _buildDateRangeFilter(),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Clear All',
                  onPressed: _clearAllFilters,
                  backgroundColor: AppColors.backgroundDark,
                  textColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: _applyFilters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.map((status) {
        final isSelected = _filters['status'] == status;
        return FilterChip(
          label: Text(
            _getStatusDisplayText(status),
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters['status'] = status;
              } else {
                _filters.remove('status');
              }
            });
          },
          backgroundColor: AppColors.backgroundDark,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCarrierFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _carrierOptions.map((carrier) {
        final isSelected = _filters['carrier'] == carrier;
        return FilterChip(
          label: Text(
            carrier,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters['carrier'] = carrier;
              } else {
                _filters.remove('carrier');
              }
            });
          },
          backgroundColor: AppColors.backgroundDark,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _serviceOptions.map((service) {
        final isSelected = _filters['serviceType'] == service;
        return FilterChip(
          label: Text(
            service,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters['serviceType'] = service;
              } else {
                _filters.remove('serviceType');
              }
            });
          },
          backgroundColor: AppColors.backgroundDark,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      children: [
        // Quick Date Range Options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateOption('Today', _getTodayRange()),
            _buildQuickDateOption('This Week', _getThisWeekRange()),
            _buildQuickDateOption('This Month', _getThisMonthRange()),
            _buildQuickDateOption('Last 30 Days', _getLast30DaysRange()),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Custom Date Range
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: _selectCustomDateRange,
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                        : 'Select custom date range',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _selectedDateRange != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateRange = null;
                        _filters.remove('dateRange');
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateOption(String label, DateTimeRange range) {
    final isSelected = _selectedDateRange != null &&
        _selectedDateRange!.start.isAtSameMomentAs(range.start) &&
        _selectedDateRange!.end.isAtSameMomentAs(range.end);
    
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDateRange = range;
            _filters['dateRange'] = {
              'start': range.start,
              'end': range.end,
            };
          } else {
            _selectedDateRange = null;
            _filters.remove('dateRange');
          }
        });
      },
      backgroundColor: AppColors.backgroundDark,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  void _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardDark,
              background: AppColors.backgroundDark,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filters['dateRange'] = {
          'start': picked.start,
          'end': picked.end,
        };
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
      _selectedDateRange = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'label_created':
        return 'Label Created';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'exception':
        return 'Exception';
      case 'failed':
        return 'Failed';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }

  DateTimeRange _getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(
      start: today,
      end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
    );
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _getLast30DaysRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(const Duration(days: 30));
    return DateTimeRange(start: start, end: end);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}