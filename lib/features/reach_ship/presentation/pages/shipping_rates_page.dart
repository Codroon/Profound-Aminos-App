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
import '../widgets/address_form_widget.dart';
import '../widgets/package_form_widget.dart';
import '../widgets/rate_card.dart';

class ShippingRatesPage extends StatefulWidget {
  const ShippingRatesPage({super.key});

  @override
  State<ShippingRatesPage> createState() => _ShippingRatesPageState();
}

class _ShippingRatesPageState extends State<ShippingRatesPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromAddressFormKey = GlobalKey<FormState>();
  final _toAddressFormKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Form data
  Address? _fromAddress;
  Address? _toAddress;
  List<Package> _packages = [];
  
  // Validation states
  bool _isFromAddressValid = false;
  bool _isToAddressValid = false;
  bool _isLoadingRates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const SharedAppbar(title: 'Compare Shipping Rates'),
      body: BlocListener<ReachShipBloc, ReachShipState>(
        listener: (context, state) {
          if (state is ShippingRatesLoaded) {
            setState(() {
              _currentStep = 2; // Move to results step
              _isLoadingRates = false; // Reset loading state
            });
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else if (state is ReachShipError) {
            setState(() {
              _isLoadingRates = false; // Reset loading state on error
            });
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
                  _buildResultsStep(),
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
          _buildStepIndicator(0, 'Addresses', Icons.location_on),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 0 ? AppColors.primary : AppColors.border,
            ),
          ),
          _buildStepIndicator(1, 'Packages', Icons.inventory_2),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 1 ? AppColors.primary : AppColors.border,
            ),
          ),
          _buildStepIndicator(2, 'Results', Icons.compare_arrows),
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
            Text('Shipping Addresses', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Enter the pickup and delivery addresses to compare shipping rates.',
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
              key: _fromAddressFormKey,
              onAddressChanged: (address) {
                setState(() {
                  _fromAddress = address;
                  _isFromAddressValid = _validateAddress(address);
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
              key: _toAddressFormKey,
              onAddressChanged: (address) {
                setState(() {
                  _toAddress = address;
                  _isToAddressValid = _validateAddress(address);
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
          Text('Package Details', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Add details about the packages you want to ship.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Packages List
          if (_packages.isNotEmpty)
            ..._packages.asMap().entries.map((entry) {
              final index = entry.key;
              final package = entry.value;
              final isValid = package.length > 0 && package.width > 0 && package.height > 0 && package.weight > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isValid ? AppColors.border : AppColors.error,
                    width: isValid ? 1 : 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isValid ? Icons.check_circle : Icons.error,
                              color: isValid ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Package ${index + 1}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                    const SizedBox(height: 8),
                    Text(
                      'Dimensions: ${package.length} × ${package.width} × ${package.height} ${package.dimensionUnit}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Weight: ${package.weight} ${package.weightUnit}',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (!isValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Invalid package: All dimensions and weight must be greater than 0',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),

          // Add Package Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Package',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Add Package Details',
                  onPressed: _showAddPackageDialog,
                ),
              ],
            ),
          ),
          
          // Validation Summary
          if (_packages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _arePackagesValid() ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _arePackagesValid() ? AppColors.success : AppColors.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _arePackagesValid() ? Icons.check_circle : Icons.error,
                    color: _arePackagesValid() ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _arePackagesValid() 
                        ? 'All packages are valid and ready for rate comparison'
                        : 'Please ensure all packages have valid dimensions and weight greater than 0',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _arePackagesValid() ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    return BlocBuilder<ReachShipBloc, ReachShipState>(
      builder: (context, state) {
        if (state is ReachShipLoading || _isLoadingRates) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Comparing shipping rates...',
                  style: AppTextStyles.bodyMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        if (state is ShippingRatesLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shipping Options', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Choose the best shipping option for your needs.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Rates List
                ...state.rates.map((rate) {
                  return RateCard(
                    rate: rate,
                    onSelect: () => _selectRate(rate),
                  );
                }).toList(),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('No rates found', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Text(
                'Please check your addresses and package details',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                textStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                text: 'Back',
                onPressed: _goToPreviousStep,
                backgroundColor: AppColors.cardDark,
                textColor: AppColors.textPrimary,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 1),
          Expanded(
            child: CustomButton(
              textStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              text: _isLoadingRates && _currentStep == 1 ? 'Getting Rates...' : _getNextButtonText(),
              onPressed: _canProceed() ? _goToNextStep : null,
              isLoading: _isLoadingRates && _currentStep == 1,
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue to Packages';
      case 1:
        return 'Compare Rates';
      case 2:
        return 'Start Over';
      default:
        return 'Next';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _isFromAddressValid && _isToAddressValid && !_isLoadingRates;
      case 1:
        return _packages.isNotEmpty && _arePackagesValid() && !_isLoadingRates;
      case 2:
        return true;
      default:
        return false;
    }
  }
  
  bool _validateAddress(Address? address) {
    if (address == null) return false;
    return address.name?.isNotEmpty == true &&
           address.street1.isNotEmpty &&
           address.city.isNotEmpty &&
           address.state.isNotEmpty &&
           address.postalCode.isNotEmpty &&
           address.country.isNotEmpty;
  }
  
  bool _arePackagesValid() {
    if (_packages.isEmpty) return false;
    return _packages.every((package) => 
      package.length > 0 &&
      package.width > 0 &&
      package.height > 0 &&
      package.weight > 0
    );
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 1) {
        // Validate packages before proceeding
        if (!_arePackagesValid()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please ensure all packages have valid dimensions and weight'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        
        // Set loading state and trigger rate comparison
        setState(() {
          _isLoadingRates = true;
        });
        
        context.read<ReachShipBloc>().add(
          GetShippingRatesEvent(
            fromAddress: _fromAddress!,
            toAddress: _toAddress!,
            packages: _packages,
          ),
        );
      } else {
        // Validate addresses before proceeding
        if (_currentStep == 0 && (!_isFromAddressValid || !_isToAddressValid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in all required address fields'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Start over
      _resetForm();
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

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _fromAddress = null;
      _toAddress = null;
      _packages.clear();
      _isFromAddressValid = false;
      _isToAddressValid = false;
      _isLoadingRates = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  void _selectRate(rate) {
    // Navigate to shipment creation with selected rate
    Navigator.pop(context, rate);
  }
}
