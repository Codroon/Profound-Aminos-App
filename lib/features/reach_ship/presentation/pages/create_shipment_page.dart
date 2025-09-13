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
import '../../models/address.dart';
import '../../models/package.dart';
import '../../models/rate.dart';
import '../../models/shipment.dart';
import '../widgets/address_form_widget.dart';
import '../widgets/package_form_widget.dart';
import '../widgets/rate_card.dart';
import '../widgets/shipment_summary_card.dart';

class CreateShipmentPage extends StatefulWidget {
  final Rate? selectedRate;
  final Address? fromAddress;
  final Address? toAddress;
  final List<Package>? packages;
  final Shipment? editingShipment;

  const CreateShipmentPage({
    super.key,
    this.selectedRate,
    this.fromAddress,
    this.toAddress,
    this.packages,
    this.editingShipment,
  });

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Form data
  Address? _fromAddress;
  Address? _toAddress;
  List<Package> _packages = [];
  Rate? _selectedRate;

  // Additional shipment options
  bool _requireSignature = false;
  bool _saturdayDelivery = false;
  bool _insuranceRequired = false;
  double _insuranceValue = 0.0;
  String _specialInstructions = '';

  final _insuranceController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize with passed data
    _fromAddress = widget.fromAddress;
    _toAddress = widget.toAddress;
    _packages = widget.packages ?? [];
    _selectedRate = widget.selectedRate;

    // If we have all required data, skip to confirmation
    if (_fromAddress != null &&
        _toAddress != null &&
        _packages.isNotEmpty &&
        _selectedRate != null) {
      _currentStep = 3;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _insuranceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const SharedAppbar(title: 'Create Shipment'),
      body: BlocListener<ReachShipBloc, ReachShipState>(
        listener: (context, state) {
          if (state is ShipmentCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shipment created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(state.shipment);
          } else if (state is ReachShipError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Form Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAddressStep(),
                  _buildPackageStep(),
                  _buildRateSelectionStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),

            // Bottom Navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Details', Icons.edit_outlined),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 0 ? AppColors.primary : AppColors.border,
            ),
          ),
          _buildStepIndicator(1, 'Packages', Icons.inventory_2_outlined),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 1 ? AppColors.primary : AppColors.border,
            ),
          ),
          _buildStepIndicator(2, 'Rates', Icons.local_shipping_outlined),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 2 ? AppColors.primary : AppColors.border,
            ),
          ),
          _buildStepIndicator(3, 'Confirm', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive ? Colors.white : AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipment Details', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Confirm or update the shipping addresses for your shipment.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // From Address
            Text(
              'From Address (Pickup)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AddressFormWidget(
              initialAddress: _fromAddress,
              onAddressChanged: (address) {
                setState(() {
                  _fromAddress = address;
                });
              },
            ),

            const SizedBox(height: 24),

            // To Address
            Text(
              'To Address (Delivery)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AddressFormWidget(
              initialAddress: _toAddress,
              onAddressChanged: (address) {
                setState(() {
                  _toAddress = address;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Package Information', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Confirm or update package details and add shipping options.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Packages List
          Text(
            'Packages',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          if (_packages.isNotEmpty)
            ..._packages.asMap().entries.map((entry) {
              final index = entry.key;
              final package = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package ${index + 1}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${package.length}" × ${package.width}" × ${package.height}" • ${package.weight} lbs',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removePackage(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          // Add Package Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: CustomButton(
              text: 'Add Another Package',
              onPressed: _showAddPackageDialog,
              backgroundColor: AppColors.cardDark,
              textColor: AppColors.primary,
            ),
          ),

          // Shipping Options
          Text(
            'Shipping Options',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Signature Required
                _buildOptionTile(
                  'Signature Required',
                  'Require signature upon delivery',
                  Icons.edit_outlined,
                  _requireSignature,
                  (value) => setState(() => _requireSignature = value),
                ),

                const Divider(color: AppColors.border),

                // Saturday Delivery
                _buildOptionTile(
                  'Saturday Delivery',
                  'Deliver on Saturday (additional fees may apply)',
                  Icons.weekend_outlined,
                  _saturdayDelivery,
                  (value) => setState(() => _saturdayDelivery = value),
                ),

                const Divider(color: AppColors.border),

                // Insurance
                _buildOptionTile(
                  'Insurance',
                  'Protect your shipment with insurance',
                  Icons.security_outlined,
                  _insuranceRequired,
                  (value) => setState(() => _insuranceRequired = value),
                ),

                if (_insuranceRequired) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _insuranceController,
                    hintText: 'Insurance Value (USD)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: r'$',
                    onChanged: (value) {
                      _insuranceValue = double.tryParse(value) ?? 0.0;
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Special Instructions
          Text(
            'Special Instructions',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _instructionsController,
            hintText: 'Any special delivery instructions...',
            maxLines: 3,
            onChanged: (value) {
              _specialInstructions = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRateSelectionStep() {
    return BlocBuilder<ReachShipBloc, ReachShipState>(
      builder: (context, state) {
        if (state is ReachShipLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ShippingRatesLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Shipping Rate', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Choose the best shipping option for your package.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Rates List
                ...state.rates.map((rate) {
                  final isSelected = _selectedRate?.id == rate.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RateCard(
                      rate: rate,
                      onSelect: () {
                        setState(() {
                          _selectedRate = rate;
                        });
                      },
                      isSelected: isSelected,
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }

        if (state is ReachShipError) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load shipping rates',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(text: 'Retry', onPressed: _fetchShippingRates),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Getting shipping rates...',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Shipment', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Review your shipment details before creating the label.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Selected Rate
          if (_selectedRate != null) ...[
            Text(
              'Selected Shipping Rate',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            RateCard(rate: _selectedRate!, onSelect: () {}, isSelected: true),
            const SizedBox(height: 24),
          ],

          // Shipment Summary
          if (_fromAddress != null && _toAddress != null) ...[
            ShipmentSummaryCard(
              fromAddress: _fromAddress!,
              toAddress: _toAddress!,
              packages: _packages,
              selectedRate: _selectedRate,
              requireSignature: _requireSignature,
              saturdayDelivery: _saturdayDelivery,
              insuranceRequired: _insuranceRequired,
              insuranceValue: _insuranceValue,
              specialInstructions: _specialInstructions,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                'Please complete the shipping addresses before proceeding.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<ReachShipBloc, ReachShipState>(
        builder: (context, state) {
          final isLoading = state is ReachShipLoading;

          return Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: CustomButton(
                    text: 'Back',
                    onPressed: isLoading ? null : _goToPreviousStep,
                    backgroundColor: AppColors.cardDark,
                    textColor: AppColors.textPrimary,
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: _getNextButtonText(),
                  onPressed: _canProceed() && !isLoading ? _goToNextStep : null,
                  isLoading: isLoading,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue to Packages';
      case 1:
        return 'Select Shipping Rate';
      case 2:
        return 'Review Shipment';
      case 3:
        return 'Create Shipment';
      default:
        return 'Next';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _fromAddress != null && _toAddress != null;
      case 1:
        return _packages.isNotEmpty;
      case 2:
        return _fromAddress != null &&
            _toAddress != null &&
            _packages.isNotEmpty; // Need data to get rates
      case 3:
        return _selectedRate != null;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // If we're moving to the rate selection step, fetch rates
      if (_currentStep == 2) {
        _fetchShippingRates();
      }
    } else {
      // Create shipment
      _createShipment();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddPackageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => PackageFormWidget(
            onPackageAdded: (package) {
              setState(() {
                _packages.add(package);
              });
            },
          ),
    );
  }

  void _removePackage(int index) {
    setState(() {
      _packages.removeAt(index);
    });
  }

  void _fetchShippingRates() {
    if (_fromAddress != null && _toAddress != null && _packages.isNotEmpty) {
      context.read<ReachShipBloc>().add(
        GetShippingRatesEvent(
          fromAddress: _fromAddress!,
          toAddress: _toAddress!,
          packages: _packages,
        ),
      );
    }
  }

  void _createShipment() {
    if (_selectedRate != null && _fromAddress != null && _toAddress != null) {
      context.read<ReachShipBloc>().add(
        CreateShipmentEvent(
          orderId: DateTime.now().millisecondsSinceEpoch.toString(),
          fromAddress: _fromAddress!,
          toAddress: _toAddress!,
          packages: _packages,
          rateId: _selectedRate!.id,
          carrier: _selectedRate!.carrier ?? 'ups',
          metadata: {
            'signature_required': _requireSignature,
            'saturday_delivery': _saturdayDelivery,
            'insurance_required': _insuranceRequired,
            'insurance_value': _insuranceValue,
            'special_instructions': _specialInstructions,
          },
        ),
      );
      log(
        'Creating shipment with data: '
        'From: ${_fromAddress!.toJson()}, '
        'To: ${_toAddress!.toJson()}, '
        'Packages: ${_packages.map((p) => p.toJson()).toList()}, '
        'Rate: ${_selectedRate!.toJson()}',
      );
    }
  }
}
