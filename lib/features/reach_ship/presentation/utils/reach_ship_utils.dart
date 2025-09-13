import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/reach_ship_constants.dart';
import '../../models/shipment.dart';
import '../../models/address.dart';
import '../../models/package.dart';
import '../../models/shipping_rate.dart';
import '../../models/tracking_update.dart';

class ReachShipUtils {
  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd/yy').format(date);
  }

  static String formatDateTimeShort(DateTime dateTime) {
    return DateFormat('MM/dd/yy hh:mm a').format(dateTime);
  }

  // Currency Formatting
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CAD':
        return r'C$';
      case 'AUD':
        return r'A$';
      default:
        return r'$';
    }
  }

  // Weight Formatting
  static String formatWeight(double weight, String unit) {
    if (weight == weight.toInt()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(2)} $unit';
  }

  // Dimension Formatting
  static String formatDimensions(double length, double width, double height, String unit) {
    return '${_formatDimension(length)} x ${_formatDimension(width)} x ${_formatDimension(height)} $unit';
  }

  static String _formatDimension(double dimension) {
    if (dimension == dimension.toInt()) {
      return dimension.toInt().toString();
    }
    return dimension.toStringAsFixed(1);
  }

  // Status Formatting
  static String formatStatus(String status) {
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  // Color Helpers
  static Color getCarrierColor(String carrier) {
    return ReachShipConstants.carrierColors[carrier] ?? 
           ReachShipConstants.carrierColors['Default']!;
  }

  static Color getStatusColor(String status) {
    return ReachShipConstants.statusColors[status.toLowerCase()] ?? 
           ReachShipConstants.statusColors['pending']!;
  }

  // Icon Helpers
  static IconData getStatusIcon(String status) {
    return ReachShipConstants.statusIcons[status.toLowerCase()] ?? 
           ReachShipConstants.statusIcons['pending']!;
  }

  static IconData getServiceTypeIcon(String serviceType) {
    return ReachShipConstants.serviceTypeIcons[serviceType.toLowerCase()] ?? 
           ReachShipConstants.serviceTypeIcons['standard']!;
  }

  static IconData getPackageTypeIcon(String packageType) {
    return ReachShipConstants.packageTypeIcons[packageType.toLowerCase()] ?? 
           ReachShipConstants.packageTypeIcons['box']!;
  }

  // Address Formatting
  static String formatAddress(Address address, {bool includeCountry = true}) {
    final parts = <String>[];
    
    if (address.street1.isNotEmpty) parts.add(address.street1);
    if (address.street2?.isNotEmpty == true) parts.add(address.street2!);
    
    final cityStateZip = <String>[];
    if (address.city.isNotEmpty) cityStateZip.add(address.city);
    if (address.state.isNotEmpty) cityStateZip.add(address.state);
    if (address.postalCode.isNotEmpty) cityStateZip.add(address.postalCode);
    
    if (cityStateZip.isNotEmpty) {
      parts.add(cityStateZip.join(', '));
    }
    
    if (includeCountry && address.country.isNotEmpty) {
      parts.add(address.country);
    }
    
    return parts.join('\n');
  }

  static String formatAddressOneLine(Address address, {bool includeCountry = false}) {
    final parts = <String>[];
    
    if (address.street1.isNotEmpty) parts.add(address.street1);
    if (address.city.isNotEmpty) parts.add(address.city);
    if (address.state.isNotEmpty) parts.add(address.state);
    if (address.postalCode.isNotEmpty) parts.add(address.postalCode);
    if (includeCountry && address.country.isNotEmpty) parts.add(address.country);
    
    return parts.join(', ');
  }

  // Package Summary
  static String getPackageSummary(List<Package> packages) {
    if (packages.isEmpty) return 'No packages';
    if (packages.length == 1) return '1 package';
    return '${packages.length} packages';
  }

  static double getTotalWeight(List<Package> packages) {
    return packages.fold(0.0, (sum, package) => sum + package.weight);
  }

  static double getTotalValue(List<Package> packages) {
    return packages.fold(0.0, (sum, package) => sum + (package.declaredValue ?? 0.0));
  }

  // Shipment Helpers
  static String getShipmentDisplayId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  static String getTrackingDisplayNumber(String trackingNumber) {
    if (trackingNumber.length <= 12) return trackingNumber;
    return '${trackingNumber.substring(0, 6)}...${trackingNumber.substring(trackingNumber.length - 6)}';
  }

  static Duration getEstimatedDeliveryTime(ShippingRate rate) {
    // Parse delivery time from rate service type or description
    final serviceType = rate.serviceName.toLowerCase();
    
    if (serviceType.contains('overnight') || serviceType.contains('next day')) {
      return const Duration(days: 1);
    } else if (serviceType.contains('two day') || serviceType.contains('2 day')) {
      return const Duration(days: 2);
    } else if (serviceType.contains('express')) {
      return const Duration(days: 3);
    } else if (serviceType.contains('ground') || serviceType.contains('standard')) {
      return const Duration(days: 5);
    } else if (serviceType.contains('international')) {
      return const Duration(days: 10);
    }
    
    return const Duration(days: 5); // Default
  }

  static String getEstimatedDeliveryDate(ShippingRate rate) {
    final estimatedTime = getEstimatedDeliveryTime(rate);
    final deliveryDate = DateTime.now().add(estimatedTime);
    return formatDate(deliveryDate);
  }

  // Validation Helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPhone.length >= 10;
  }

  static bool isValidZipCode(String zipCode, String country) {
    if (country.toLowerCase() == 'united states' || country.toLowerCase() == 'us') {
      return RegExp(r'^\d{5}(-\d{4})?$').hasMatch(zipCode);
    }
    return zipCode.isNotEmpty; // Basic validation for other countries
  }

  static bool isValidTrackingNumber(String trackingNumber) {
    return trackingNumber.length >= 8 && trackingNumber.length <= 50;
  }

  // Search and Filter Helpers
  static bool matchesSearchQuery(Shipment shipment, String query) {
    if (query.isEmpty) return true;
    
    final lowerQuery = query.toLowerCase();
    
    return (shipment.trackingNumber?.toLowerCase().contains(lowerQuery) ?? false) ||
           shipment.id.toLowerCase().contains(lowerQuery) ||
           shipment.selectedRate.carrierName.toLowerCase().contains(lowerQuery) ||
           shipment.status.name.toLowerCase().contains(lowerQuery) ||
           formatAddressOneLine(shipment.fromAddress).toLowerCase().contains(lowerQuery) ||
           formatAddressOneLine(shipment.toAddress).toLowerCase().contains(lowerQuery);
  }

  static List<Shipment> filterShipments(
    List<Shipment> shipments, {
    String? status,
    String? carrier,
    String? serviceType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return shipments.where((shipment) {
      // Status filter
      if (status != null && status.isNotEmpty && 
          shipment.status.name.toLowerCase() != status.toLowerCase()) {
        return false;
      }
      
      // Carrier filter
      if (carrier != null && carrier.isNotEmpty && 
          shipment.selectedRate.carrierName.toLowerCase() != carrier.toLowerCase()) {
        return false;
      }
      
      // Service type filter
      if (serviceType != null && serviceType.isNotEmpty && 
          shipment.selectedRate.serviceName.toLowerCase() != serviceType.toLowerCase()) {
        return false;
      }
      
      // Date range filter
      if (startDate != null && shipment.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && shipment.createdAt.isAfter(endDate)) {
        return false;
      }
      
      // Search query filter
      if (searchQuery != null && !matchesSearchQuery(shipment, searchQuery)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Sorting Helpers
  static List<Shipment> sortShipments(
    List<Shipment> shipments,
    String sortBy, {
    bool ascending = true,
  }) {
    final sorted = List<Shipment>.from(shipments);
    
    switch (sortBy.toLowerCase()) {
      case 'date':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'status':
        sorted.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case 'carrier':
        sorted.sort((a, b) => a.selectedRate.carrierName.compareTo(b.selectedRate.carrierName));
        break;
      case 'cost':
        sorted.sort((a, b) => a.selectedRate.rate.compareTo(b.selectedRate.rate));
        break;
      case 'tracking':
        sorted.sort((a, b) => (a.trackingNumber ?? '').compareTo(b.trackingNumber ?? ''));
        break;
      default:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return ascending ? sorted : sorted.reversed.toList();
  }

  // Error Handling
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return ReachShipConstants.genericErrorMessage;
  }

  // Loading States
  static Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: ReachShipConstants.mediumSpacing),
            Text(message),
          ],
        ],
      ),
    );
  }

  static Widget buildErrorWidget(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: ReachShipConstants.extraLargeIconSize,
            color: Colors.red,
          ),
          const SizedBox(height: ReachShipConstants.mediumSpacing),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: ReachShipConstants.mediumSpacing),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildEmptyWidget(String message, {IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox,
            size: ReachShipConstants.extraLargeIconSize,
            color: Colors.grey,
          ),
          const SizedBox(height: ReachShipConstants.mediumSpacing),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}