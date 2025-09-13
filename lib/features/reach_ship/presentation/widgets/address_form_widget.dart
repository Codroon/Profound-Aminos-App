import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../models/address.dart';
import '../../utils/country_code_mapper.dart';

class AddressFormWidget extends StatefulWidget {
  final Function(Address) onAddressChanged;
  final Address? initialAddress;

  const AddressFormWidget({
    super.key,
    required this.onAddressChanged,
    this.initialAddress,
  });

  @override
  State<AddressFormWidget> createState() => _AddressFormWidgetState();
}

class _AddressFormWidgetState extends State<AddressFormWidget> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _streetController = TextEditingController();
  final _street2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isResidential = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _populateFields(widget.initialAddress!);
    }

    // Set default country
    _countryController.text = 'US';

    // Add listeners to update address on changes
    _addListeners();
  }

  void _populateFields(Address address) {
    _nameController.text = address.name ?? '';
    _companyController.text = address.company ?? '';
    _streetController.text = address.street1;
    _street2Controller.text = address.street2 ?? '';
    _cityController.text = address.city;
    _stateController.text = address.state;
    _zipController.text = address.postalCode;
    _countryController.text = address.country;
    _phoneController.text = address.phone ?? '';
    _emailController.text = address.email ?? '';
    _isResidential =
        false; // Default value since Address model doesn't have isResidential
  }

  void _addListeners() {
    final controllers = [
      _nameController,
      _companyController,
      _streetController,
      _street2Controller,
      _cityController,
      _stateController,
      _zipController,
      _countryController,
      _phoneController,
      _emailController,
    ];

    for (final controller in controllers) {
      controller.addListener(_updateAddress);
    }
  }

  void _updateAddress() {
    if (_nameController.text.isNotEmpty &&
        _streetController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _stateController.text.isNotEmpty &&
        _zipController.text.isNotEmpty &&
        _countryController.text.isNotEmpty) {
      final address = Address(
        name: _nameController.text,
        company:
            _companyController.text.isEmpty ? null : _companyController.text,
        street1: _streetController.text,
        street2:
            _street2Controller.text.isEmpty ? null : _street2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _zipController.text,
        country: _countryController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      widget.onAddressChanged(address);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _nameController,
                  hintText: 'Full Name *',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _companyController,
                  hintText: 'Company (Optional)',
                  prefixIcon: Icons.business_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Street Address
          CustomTextField(
            controller: _streetController,
            hintText: 'Street Address *',
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Street address is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          CustomTextField(
            controller: _street2Controller,
            hintText: 'Apartment, suite, etc. (Optional)',
            prefixIcon: Icons.home_outlined,
          ),

          const SizedBox(height: 16),

          // City, State, ZIP
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cityController,
                  hintText: 'City *',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  hintText: 'State *',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _zipController,
                  hintText: 'ZIP Code *',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ZIP code is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Country
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              final countries = CountryCodeMapper.getAllCountryNames();
              return countries.where((String country) {
                return country.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _countryController.text = selection;
              _updateAddress();
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onEditingComplete,
            ) {
              _countryController.text = controller.text;
              return CustomTextField(
                controller: controller,
                focusNode: focusNode,
                hintText: 'Country * (e.g., Pakistan, United States)',
                prefixIcon: Icons.flag_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Country is required';
                  }
                  // Validate that it's a recognized country
                  final countryCode = CountryCodeMapper.getCountryCode(value);
                  if (countryCode.length != 2) {
                    return 'Please enter a valid country name';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateAddress();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(option, style: AppTextStyles.bodySmall),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Contact Details
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Residential Checkbox
          Row(
            children: [
              Checkbox(
                value: _isResidential,
                onChanged: (value) {
                  setState(() {
                    _isResidential = value ?? false;
                  });
                  _updateAddress();
                },
                activeColor: AppColors.primary,
                checkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a residential address',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Address Type Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Residential addresses may have different shipping rates and delivery options.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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
}
