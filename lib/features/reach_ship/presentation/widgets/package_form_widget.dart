import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../models/package.dart';

class PackageFormWidget extends StatefulWidget {
  final Function(Package) onPackageAdded;
  final Package? initialPackage;

  const PackageFormWidget({
    super.key,
    required this.onPackageAdded,
    this.initialPackage,
  });

  @override
  State<PackageFormWidget> createState() => _PackageFormWidgetState();
}

class _PackageFormWidgetState extends State<PackageFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedUnit = 'in';
  String _selectedWeightUnit = 'lbs';

  final List<String> _dimensionUnits = ['in', 'cm'];
  final List<String> _weightUnits = ['lbs', 'kg', 'oz', 'g'];

  @override
  void initState() {
    super.initState();
    if (widget.initialPackage != null) {
      _populateFields(widget.initialPackage!);
    }
  }

  void _populateFields(Package package) {
    _lengthController.text = package.length.toString();
    _widthController.text = package.width.toString();
    _heightController.text = package.height.toString();
    _weightController.text = package.weight.toString();
    _valueController.text = package.declaredValue?.toString() ?? '';
    _descriptionController.text = package.description ?? '';
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.cardDark,
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Package Details', style: AppTextStyles.h3),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter the dimensions and weight of your package.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // Dimensions Section
                Text(
                  'Dimensions',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Dimension Unit Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unit: ', style: AppTextStyles.bodySmall),
                      ..._dimensionUnits.map((unit) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: unit,
                                groupValue: _selectedUnit,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUnit = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(unit, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dimensions Input
                Wrap(
                  runSpacing: 8,
                  children: [
                    CustomTextField(
                      controller: _lengthController,
                      hintText: 'Length',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: _selectedUnit,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(width: 12),
                    CustomTextField(
                      controller: _widthController,
                      hintText: 'Width',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: _selectedUnit,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(width: 12),
                    CustomTextField(
                      controller: _heightController,
                      hintText: 'Height',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: _selectedUnit,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Weight Section
                Text(
                  'Weight',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Weight Unit Selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    direction: Axis.horizontal,
                    children: [
                      Text('Unit: ', style: AppTextStyles.bodySmall),
                      ..._weightUnits.map((unit) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: unit,
                                groupValue: _selectedWeightUnit,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedWeightUnit = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(unit, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Weight Input
                CustomTextField(
                  controller: _weightController,
                  hintText: 'Package Weight',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixText: _selectedWeightUnit,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Weight is required';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Optional Fields
                Text(
                  'Additional Information (Optional)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  controller: _valueController,
                  hintText: 'Package Value (USD)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixText: r'$',
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descriptionController,
                  hintText: 'Package Description',
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Package Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Package Preview',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPackagePreview(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        textStyle: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: AppColors.cardDark,
                        textColor: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        textStyle: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        text: 'Add Package',
                        onPressed: _addPackage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPackagePreview() {
    final length = _lengthController.text;
    final width = _widthController.text;
    final height = _heightController.text;
    final weight = _weightController.text;

    if (length.isEmpty || width.isEmpty || height.isEmpty || weight.isEmpty) {
      return 'Enter dimensions and weight to see preview';
    }

    return 'Dimensions: $length × $width × $height $_selectedUnit\nWeight: $weight $_selectedWeightUnit';
  }

  void _addPackage() {
    if (_formKey.currentState!.validate()) {
      final package = Package(
        length: double.parse(_lengthController.text),
        width: double.parse(_widthController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        declaredValue:
            _valueController.text.isEmpty
                ? null
                : double.parse(_valueController.text),
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        dimensionUnit: _selectedUnit,
        weightUnit: _selectedWeightUnit,
      );

      widget.onPackageAdded(package);
      Navigator.of(context).pop();
    }
  }
}
