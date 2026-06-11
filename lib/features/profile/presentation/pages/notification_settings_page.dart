import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/core/theme/app_text_style.dart';
import 'package:woo_management_app/core/services/push_notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Shared preferences keys
  static const String _keyOrdersCreate = 'pref_orders_create';
  static const String _keyOrdersUpdate = 'pref_orders_update';
  static const String _keyOrdersRefund = 'pref_orders_refund';

  static const String _keyShipmentCreate = 'pref_shipment_create';
  static const String _keyShipmentUpdate = 'pref_shipment_update';
  static const String _keyShipmentDelivered = 'pref_shipment_delivered';

  static const String _keyGorgiasCreate = 'pref_gorgias_create';
  static const String _keyGorgiasUpdate = 'pref_gorgias_update';
  static const String _keyGorgiasMessage = 'pref_gorgias_message';

  // Local switch states
  bool _ordersCreate = true;
  bool _ordersUpdate = true;
  bool _ordersRefund = true;

  bool _shipmentCreate = true;
  bool _shipmentUpdate = true;
  bool _shipmentDelivered = true;

  bool _gorgiasCreate = true;
  bool _gorgiasUpdate = true;
  bool _gorgiasMessage = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _ordersCreate = prefs.getBool(_keyOrdersCreate) ?? true;
        _ordersUpdate = prefs.getBool(_keyOrdersUpdate) ?? true;
        _ordersRefund = prefs.getBool(_keyOrdersRefund) ?? true;

        _shipmentCreate = prefs.getBool(_keyShipmentCreate) ?? true;
        _shipmentUpdate = prefs.getBool(_keyShipmentUpdate) ?? true;
        _shipmentDelivered = prefs.getBool(_keyShipmentDelivered) ?? true;

        _gorgiasCreate = prefs.getBool(_keyGorgiasCreate) ?? true;
        _gorgiasUpdate = prefs.getBool(_keyGorgiasUpdate) ?? true;
        _gorgiasMessage = prefs.getBool(_keyGorgiasMessage) ?? true;

        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      await PushNotificationService.instance.syncPreferences();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1F2937),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1F2937),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize which pushes are delivered to your device.',
                      style: AppTextStyles.caption.copyWith(
                        color:
                            isDark
                                ? const Color(0xFF98A0B8)
                                : const Color(0xFF6B7280),
                      ),
                    ),
                    const Gap(24),

                    // 1. Orders Notifications Section
                    _buildSectionHeader(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Orders Notifications',
                      subtitle: 'Triggers on WooCommerce purchases & lifecycle',
                    ),
                    const Gap(12),
                    _buildPreferencesCard([
                      _buildSwitchItem(
                        title: 'Order Created',
                        subtitle: 'Alert on new customer purchases',
                        value: _ordersCreate,
                        onChanged: (val) {
                          setState(() => _ordersCreate = val);
                          _updatePreference(_keyOrdersCreate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Order Updated',
                        subtitle:
                            'Alert on order processing/shipping status shifts',
                        value: _ordersUpdate,
                        onChanged: (val) {
                          setState(() => _ordersUpdate = val);
                          _updatePreference(_keyOrdersUpdate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Order Refunded',
                        subtitle: 'Alert on cancelled or returned payments',
                        value: _ordersRefund,
                        onChanged: (val) {
                          setState(() => _ordersRefund = val);
                          _updatePreference(_keyOrdersRefund, val);
                        },
                      ),
                    ]),
                    const Gap(24),

                    // 2. Shipment Notifications Section
                    _buildSectionHeader(
                      icon: Icons.local_shipping_outlined,
                      title: 'Shipment Notifications',
                      subtitle: 'Triggers on delivery transit details',
                    ),
                    const Gap(12),
                    _buildPreferencesCard([
                      _buildSwitchItem(
                        title: 'Shipment Created',
                        subtitle:
                            'Alert when carrier tracking/label is initiated',
                        value: _shipmentCreate,
                        onChanged: (val) {
                          setState(() => _shipmentCreate = val);
                          _updatePreference(_keyShipmentCreate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Tracking Updated',
                        subtitle:
                            'Alert when shipment hits next transit location',
                        value: _shipmentUpdate,
                        onChanged: (val) {
                          setState(() => _shipmentUpdate = val);
                          _updatePreference(_keyShipmentUpdate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Tracking Delivered',
                        subtitle:
                            'Alert when shipment reaches buyer destination',
                        value: _shipmentDelivered,
                        onChanged: (val) {
                          setState(() => _shipmentDelivered = val);
                          _updatePreference(_keyShipmentDelivered, val);
                        },
                      ),
                    ]),
                    const Gap(24),

                    // 3. Gorgias Notifications Section
                    _buildSectionHeader(
                      icon: Icons.message_outlined,
                      title: 'Gorgias Helpdesk Notifications',
                      subtitle: 'Triggers on customer service tickets',
                    ),
                    const Gap(12),
                    _buildPreferencesCard([
                      _buildSwitchItem(
                        title: 'Ticket Created',
                        subtitle:
                            'Alert on new customer support ticket arrivals',
                        value: _gorgiasCreate,
                        onChanged: (val) {
                          setState(() => _gorgiasCreate = val);
                          _updatePreference(_keyGorgiasCreate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Ticket Updated',
                        subtitle: 'Alert on priority or assignment changes',
                        value: _gorgiasUpdate,
                        onChanged: (val) {
                          setState(() => _gorgiasUpdate = val);
                          _updatePreference(_keyGorgiasUpdate, val);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchItem(
                        title: 'Message Created',
                        subtitle: 'Alert on new customer dialogue responses',
                        value: _gorgiasMessage,
                        onChanged: (val) {
                          setState(() => _gorgiasMessage = val);
                          _updatePreference(_keyGorgiasMessage, val);
                        },
                      ),
                    ]),
                    const Gap(32),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? const Color(0xFFEAF0FF)
                          : const Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color:
                      isDark
                          ? const Color(0xFF98A0B8)
                          : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15182B) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? const Color(0xFFEAF0FF)
                            : const Color(0xFF1F2937),
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isDark
                            ? const Color(0xFF98A0B8)
                            : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor:
                isDark ? const Color(0xFF98A0B8) : const Color(0xFF9CA3AF),
            inactiveTrackColor:
                isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
      indent: 16,
      endIndent: 16,
    );
  }
}
