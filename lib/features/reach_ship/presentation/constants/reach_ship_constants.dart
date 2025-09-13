import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ReachShipConstants {
  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;

  // Card Dimensions
  static const double cardElevation = 2.0;
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;

  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;
  static const double buttonBorderRadius = 8.0;

  // Form Field Dimensions
  static const double textFieldHeight = 56.0;
  static const double textFieldBorderRadius = 8.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Carrier Colors
  static const Map<String, Color> carrierColors = {
    'FedEx': Color(0xFF4D148C),
    'UPS': Color(0xFF8B4513),
    'USPS': Color(0xFF1E3A8A),
    'DHL': Color(0xFFFFD700),
    'Amazon': Color(0xFFFF9900),
    'OnTrac': Color(0xFF00A651),
    'LaserShip': Color(0xFFE31837),
    'Default': AppColors.primary,
  };

  // Status Colors
  static const Map<String, Color> statusColors = {
    'pending': Color(0xFFF59E0B),
    'confirmed': Color(0xFF3B82F6),
    'picked_up': Color(0xFF8B5CF6),
    'in_transit': Color(0xFF06B6D4),
    'out_for_delivery': Color(0xFF10B981),
    'delivered': Color(0xFF059669),
    'exception': Color(0xFFEF4444),
    'cancelled': Color(0xFF6B7280),
    'returned': Color(0xFFDC2626),
  };

  // Service Type Icons
  static const Map<String, IconData> serviceTypeIcons = {
    'standard': Icons.local_shipping,
    'express': Icons.flash_on,
    'overnight': Icons.flight_takeoff,
    'ground': Icons.directions_car,
    'freight': Icons.local_shipping,
    'international': Icons.public,
    'same_day': Icons.today,
    'two_day': Icons.calendar_view_day,
  };

  // Package Type Icons
  static const Map<String, IconData> packageTypeIcons = {
    'box': Icons.inventory_2,
    'envelope': Icons.mail,
    'tube': Icons.straighten,
    'pallet': Icons.view_module,
    'bag': Icons.shopping_bag,
    'custom': Icons.category,
  };

  // Shipment Status Icons
  static const Map<String, IconData> statusIcons = {
    'pending': Icons.schedule,
    'confirmed': Icons.check_circle_outline,
    'picked_up': Icons.local_shipping,
    'in_transit': Icons.local_shipping,
    'out_for_delivery': Icons.delivery_dining,
    'delivered': Icons.check_circle,
    'exception': Icons.error_outline,
    'cancelled': Icons.cancel,
    'returned': Icons.keyboard_return,
  };

  // Quick Action Icons
  static const Map<String, IconData> quickActionIcons = {
    'create_shipment': Icons.add_box,
    'compare_rates': Icons.compare_arrows,
    'track_shipment': Icons.track_changes,
    'manage_shipments': Icons.list_alt,
    'address_book': Icons.contacts,
    'reports': Icons.analytics,
    'settings': Icons.settings,
    'help': Icons.help_outline,
  };

  // Default Values
  static const String defaultCountry = 'United States';
  static const String defaultCurrency = 'USD';
  static const String defaultWeightUnit = 'lbs';
  static const String defaultDimensionUnit = 'in';

  // Validation
  static const int maxTrackingNumberLength = 50;
  static const int maxAddressLineLength = 100;
  static const int maxCityLength = 50;
  static const int maxStateLength = 50;
  static const int maxZipLength = 20;
  static const int maxPhoneLength = 20;
  static const int maxEmailLength = 100;
  static const int maxPackageDescriptionLength = 200;
  static const int maxSpecialInstructionsLength = 500;

  // Limits
  static const double maxPackageWeight = 150.0;
  static const double maxPackageDimension = 108.0;
  static const double maxPackageValue = 50000.0;
  static const int maxPackagesPerShipment = 50;
  static const int maxShipmentsPerPage = 20;

  // Error Messages
  static const String genericErrorMessage =
      'An error occurred. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String validationErrorMessage =
      'Please check your input and try again.';
  static const String notFoundErrorMessage =
      'The requested item was not found.';
  static const String unauthorizedErrorMessage =
      'You are not authorized to perform this action.';

  // Success Messages
  static const String shipmentCreatedMessage = 'Shipment created successfully!';
  static const String shipmentUpdatedMessage = 'Shipment updated successfully!';
  static const String shipmentCancelledMessage =
      'Shipment cancelled successfully!';
  static const String ratesLoadedMessage =
      'Shipping rates loaded successfully!';
  static const String trackingUpdatedMessage = 'Tracking information updated!';

  // Loading Messages
  static const String loadingRatesMessage = 'Loading shipping rates...';
  static const String creatingShipmentMessage = 'Creating shipment...';
  static const String updatingShipmentMessage = 'Updating shipment...';
  static const String trackingShipmentMessage = 'Tracking shipment...';
  static const String loadingShipmentsMessage = 'Loading shipments...';

  // Placeholder Texts
  static const String searchPlaceholder = 'Search shipments...';
  static const String trackingNumberPlaceholder = 'Enter tracking number';
  static const String addressPlaceholder = 'Enter address';
  static const String cityPlaceholder = 'Enter city';
  static const String statePlaceholder = 'Enter state';
  static const String zipPlaceholder = 'Enter ZIP code';
  static const String phonePlaceholder = 'Enter phone number';
  static const String emailPlaceholder = 'Enter email address';
  static const String weightPlaceholder = 'Enter weight';
  static const String lengthPlaceholder = 'Enter length';
  static const String widthPlaceholder = 'Enter width';
  static const String heightPlaceholder = 'Enter height';
  static const String valuePlaceholder = 'Enter value';
  static const String descriptionPlaceholder = 'Enter description';
  static const String instructionsPlaceholder = 'Enter special instructions';

  // Button Labels
  static const String createShipmentLabel = 'Create Shipment';
  static const String updateShipmentLabel = 'Update Shipment';
  static const String cancelShipmentLabel = 'Cancel Shipment';
  static const String compareRatesLabel = 'Compare Rates';
  static const String selectRateLabel = 'Select Rate';
  static const String trackShipmentLabel = 'Track Shipment';
  static const String saveLabel = 'Save';
  static const String cancelLabel = 'Cancel';
  static const String continueLabel = 'Continue';
  static const String backLabel = 'Back';
  static const String nextLabel = 'Next';
  static const String finishLabel = 'Finish';
  static const String editLabel = 'Edit';
  static const String deleteLabel = 'Delete';
  static const String viewLabel = 'View';
  static const String refreshLabel = 'Refresh';
  static const String filterLabel = 'Filter';
  static const String clearLabel = 'Clear';
  static const String applyLabel = 'Apply';
  static const String resetLabel = 'Reset';

  // Tab Labels
  static const String allTabLabel = 'All';
  static const String pendingTabLabel = 'Pending';
  static const String inTransitTabLabel = 'In Transit';
  static const String deliveredTabLabel = 'Delivered';
  static const String timelineTabLabel = 'Timeline';
  static const String detailsTabLabel = 'Details';

  // Section Headers
  static const String overviewSectionHeader = 'Overview';
  static const String quickActionsSectionHeader = 'Quick Actions';
  static const String recentShipmentsSectionHeader = 'Recent Shipments';
  static const String addressesSectionHeader = 'Addresses';
  static const String packagesSectionHeader = 'Packages';
  static const String ratesSectionHeader = 'Shipping Rates';
  static const String trackingSectionHeader = 'Tracking Information';
  static const String summarySectionHeader = 'Summary';
  static const String filtersSectionHeader = 'Filters';

  // Countries List (commonly used)
  static const List<String> countries = [
    'United States',
    'Canada',
    'Mexico',
    'United Kingdom',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Australia',
    'Japan',
    'China',
    'India',
    'Brazil',
  ];

  // US States List
  static const List<String> usStates = [
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
  ];

  // Weight Units
  static const List<String> weightUnits = ['lbs', 'kg', 'oz', 'g'];

  // Dimension Units
  static const List<String> dimensionUnits = ['in', 'cm', 'ft', 'm'];

  // Package Types
  static const List<String> packageTypes = [
    'Box',
    'Envelope',
    'Tube',
    'Pallet',
    'Bag',
    'Custom',
  ];

  // Service Types
  static const List<String> serviceTypes = [
    'Standard',
    'Express',
    'Overnight',
    'Ground',
    'Freight',
    'International',
    'Same Day',
    'Two Day',
  ];

  // Carriers
  static const List<String> carriers = [
    'FedEx',
    'UPS',
    'USPS',
    'DHL',
    'Amazon',
    'OnTrac',
    'LaserShip',
  ];

  // Shipment Statuses
  static const List<String> shipmentStatuses = [
    'Pending',
    'Confirmed',
    'Picked Up',
    'In Transit',
    'Out for Delivery',
    'Delivered',
    'Exception',
    'Cancelled',
    'Returned',
  ];

  // API Base URLs
  static const String sandboxBaseUrl = 'https://api.reachship.com/sandbox/v1';
  static const String productionBaseUrl = 'https://api.reachship.com/production/v1';

  // API Endpoints
  static const String ratesEndpoint = '/rates';
  static const String shipmentsEndpoint = '/shipments';
  static const String trackShipmentEndpoint = '/shipments';
  static const String printLabelEndpoint = '/print-label';
  static const String trackingEndpoint = '/track-shipment';
  static const String pickupEndpoint = '/pickups';
  static const String pickupsEndpoint = '/pickups';
  static const String addressValidationEndpoint = '/addresses/validate';
  static const String carriersEndpoint = '/carriers';
}
