// Export ShippingRate as Rate for backward compatibility
import 'package:woo_management_app/features/reach_ship/models/shipping_rate.dart';

export 'shipping_rate.dart' show ShippingRate;

// Type alias for easier usage
typedef Rate = ShippingRate;
