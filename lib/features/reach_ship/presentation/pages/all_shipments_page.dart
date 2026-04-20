import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/shipment.dart';
import '../../models/address.dart';
import '../../models/shipping_rate.dart';
import '../widgets/shipment_detail_bottom_sheet.dart';

enum DateFilter {
  today,
  thisWeek,
  thisMonth,
  thisYear,
}

class AllShipmentsPage extends StatefulWidget {
  const AllShipmentsPage({super.key});

  @override
  State<AllShipmentsPage> createState() => _AllShipmentsPageState();
}

class _AllShipmentsPageState extends State<AllShipmentsPage> {
  DateFilter _selectedFilter = DateFilter.thisMonth;

  // Dummy data matching the screenshot exactly
  List<Shipment> get _dummyShipments {
    return [
      Shipment(
        id: '9021',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Austin', state: 'TX', name: 'Sarah Jenkins', street1: '456 Main St', postalCode: '78701', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate1', carrierId: 'usps', carrierName: 'USPS Priority', serviceName: 'Priority', serviceCode: 'priority', rate: 8.50),
        status: ShipmentStatus.inTransit,
        trackingNumber: '1Z9999999999999999',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9020',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Seattle', state: 'WA', name: 'Michael Chen', street1: '789 Pine St', postalCode: '98101', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate2', carrierId: 'ups', carrierName: 'UPS Ground', serviceName: 'Ground', serviceCode: 'ground', rate: 12.00),
        status: ShipmentStatus.pending,
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9019',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'New York', state: 'NY', name: 'Emma Thompson', street1: '321 Broadway', postalCode: '10001', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate3', carrierId: 'fedex', carrierName: 'FedEx Express', serviceName: 'Express', serviceCode: 'express', rate: 15.50),
        status: ShipmentStatus.delivered,
        trackingNumber: '1Z8888888888888888',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9018',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Miami', state: 'FL', name: 'David Rodriguez', street1: '555 Ocean Dr', postalCode: '33101', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate4', carrierId: 'dhl', carrierName: 'DHL Express', serviceName: 'Express', serviceCode: 'express', rate: 22.00),
        status: ShipmentStatus.cancelled,
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9017',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Chicago', state: 'IL', name: 'Lisa White', street1: '888 Michigan Ave', postalCode: '60601', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate5', carrierId: 'usps', carrierName: 'USPS First Class', serviceName: 'First Class', serviceCode: 'first_class', rate: 4.50),
        status: ShipmentStatus.delivered,
        trackingNumber: '1Z7777777777777777',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9016',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Denver', state: 'CO', name: 'James Wilson', street1: '111 Colorado Blvd', postalCode: '80202', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate6', carrierId: 'usps', carrierName: 'USPS Priority', serviceName: 'Priority', serviceCode: 'priority', rate: 9.00),
        status: ShipmentStatus.inTransit,
        trackingNumber: '1Z6666666666666666',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9015',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Boston', state: 'MA', name: 'Olivia Davis', street1: '222 Beacon St', postalCode: '02108', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate7', carrierId: 'ups', carrierName: 'UPS Ground', serviceName: 'Ground', serviceCode: 'ground', rate: 11.50),
        status: ShipmentStatus.delivered,
        trackingNumber: '1Z5555555555555555',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9014',
        fromAddress: Address(city: 'Warehouse', state: 'TX', name: 'Warehouse', street1: '123 Warehouse St', postalCode: '78701', country: 'US'),
        toAddress: Address(city: 'Portland', state: 'OR', name: 'Daniel Smith', street1: '333 Burnside St', postalCode: '97201', country: 'US'),
        packages: [],
        selectedRate: ShippingRate(id: 'rate8', carrierId: 'fedex', carrierName: 'FedEx Express', serviceName: 'Express', serviceCode: 'express', rate: 14.00),
        status: ShipmentStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shipments = _dummyShipments;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with back button
            _buildAppBar(context),
            
            // Date Filter
            _buildDateFilter(),
            
            // Shipments List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: shipments.length,
                itemBuilder: (context, index) {
                  return _buildShipmentItem(context, shipments[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'All Shipments',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayText() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.thisWeek:
        return 'This Week';
      case DateFilter.thisMonth:
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return 'This Month (${monthNames[now.month - 1]} ${now.year})';
      case DateFilter.thisYear:
        return 'This Year (${now.year})';
    }
  }

  void _showDateFilterDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Date Range',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Options
              _buildFilterOption(DateFilter.today, 'Today'),
              _buildFilterOption(DateFilter.thisWeek, 'This Week'),
              _buildFilterOption(DateFilter.thisMonth, 'This Month'),
              _buildFilterOption(DateFilter.thisYear, 'This Year'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(DateFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filter);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selected',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return InkWell(
      onTap: _showDateFilterDropdown,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getFilterDisplayText(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentItem(BuildContext context, Shipment shipment) {
    final statusColor = _getStatusColor(shipment.status);
    final statusText = _getStatusText(shipment.status);

    return InkWell(
      onTap: () => _showShipmentDetail(context, shipment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#ORD-${shipment.id}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Customer info and price
          Row(
            children: [
              Expanded(
                child: Text(
                  '${shipment.toAddress.name} • ${shipment.toAddress.city}, ${shipment.toAddress.state}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${shipment.selectedRate.carrierName} • \$${shipment.selectedRate.rate.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showShipmentDetail(BuildContext context, Shipment shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ShipmentDetailBottomSheet(shipment: shipment),
          );
        },
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return AppColors.success;
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return AppColors.info;
      case ShipmentStatus.pending:
      case ShipmentStatus.created:
      case ShipmentStatus.labelGenerated:
        return AppColors.warning;
      case ShipmentStatus.exception:
      case ShipmentStatus.returned:
      case ShipmentStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return 'Fulfilled';
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return 'In Transit';
      case ShipmentStatus.pending:
      case ShipmentStatus.created:
      case ShipmentStatus.labelGenerated:
        return 'Pending';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
      case ShipmentStatus.exception:
        return 'Exception';
      case ShipmentStatus.returned:
        return 'Returned';
      default:
        return 'Unknown';
    }
  }
}
