import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';

class CreateProductPage extends StatefulWidget {
  final Map<String, dynamic>? product; // If provided, we're in edit mode
  
  const CreateProductPage({super.key, this.product});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _regularPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _skuController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  String _status = 'draft';
  String _stockStatus = 'instock';
  String _productType = 'simple';
  bool _manageStock = false;
  bool _virtual = false;
  bool _downloadable = false;

  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = []; // For edit mode - URLs of already uploaded images
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoadingData = false; // For initial data loading in edit mode

  final List<String> _statusOptions = ['draft', 'publish', 'pending', 'private'];
  final List<String> _stockStatusOptions = ['instock', 'outofstock', 'onbackorder'];
  final List<String> _productTypeOptions = ['simple', 'grouped', 'external', 'variable'];

  bool get _isEditMode => widget.product != null;
  int? get _productId => widget.product?['id'];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _regularPriceController.dispose();
    _salePriceController.dispose();
    _skuController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadProductData() {
    setState(() {
      _isLoadingData = true;
    });

    final product = widget.product!;
    developer.log('Loading product data: ', name: 'CreateProductPage');

    // Load basic info
    _nameController.text = product['name']?.toString() ?? '';
    _descriptionController.text = product['description']?.toString() ?? '';
    _shortDescriptionController.text = product['short_description']?.toString() ?? '';
    
    // Load status
    final status = product['status']?.toString();
    if (status != null && _statusOptions.contains(status)) {
      _status = status;
    }

    // Load pricing
    _regularPriceController.text = product['regular_price']?.toString() ?? '';
    _salePriceController.text = product['sale_price']?.toString() ?? '';

    // Load inventory
    _skuController.text = product['sku']?.toString() ?? '';
    _manageStock = product['manage_stock'] == true;
    final stockStatus = product['stock_status']?.toString();
    if (stockStatus != null && _stockStatusOptions.contains(stockStatus)) {
      _stockStatus = stockStatus;
    }

    // Load shipping
    _weightController.text = product['weight']?.toString() ?? '';
    final dimensions = product['dimensions'] as Map<String, dynamic>?;
    if (dimensions != null) {
      _lengthController.text = dimensions['length']?.toString() ?? '';
      _widthController.text = dimensions['width']?.toString() ?? '';
      _heightController.text = dimensions['height']?.toString() ?? '';
    }

    // Load advanced options
    final productType = product['type']?.toString();
    if (productType != null && _productTypeOptions.contains(productType)) {
      _productType = productType;
    }
    _virtual = product['virtual'] == true;
    _downloadable = product['downloadable'] == true;

    // Load existing images (URLs)
    final images = product['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        final src = image['src']?.toString();
        if (src != null && src.isNotEmpty) {
          _existingImageUrls.add(src);
        }
      }
    }

    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length + _existingImageUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final pickedFile in pickedFiles) {
            if (_selectedImages.length + _existingImageUrls.length < 5) {
              _selectedImages.add(File(pickedFile.path));
            }
          }
        });
        developer.log('Selected  new images', name: 'CreateProductPage');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ')),
      );
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'type': _productType,
      'regular_price': _regularPriceController.text.trim(),
      'sale_price': _salePriceController.text.trim().isEmpty ? '' : _salePriceController.text.trim(),
      'description': _descriptionController.text.trim(),
      'short_description': _shortDescriptionController.text.trim(),
      'status': _status,
      'sku': _skuController.text.trim(),
      'manage_stock': _manageStock,
      'stock_status': _stockStatus,
      'weight': _weightController.text.trim(),
      'dimensions': {
        'length': _lengthController.text.trim(),
        'width': _widthController.text.trim(),
        'height': _heightController.text.trim(),
      },
      'virtual': _virtual,
      'downloadable': _downloadable,
    };

    if (_isEditMode && _productId != null) {
      // Update existing product
      developer.log('Updating product ', name: 'CreateProductPage');
      context.read<ProductBloc>().add(
        UpdateProduct(_productId!, data, newImages: _selectedImages, existingImageUrls: _existingImageUrls),
      );
    } else {
      // Create new product
      developer.log('Creating new product', name: 'CreateProductPage');
      context.read<ProductBloc>().add(CreateProduct(data, images: _selectedImages));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppReusableText(
        text: title,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppReusableText(
          text: label,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        const Gap(6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.inputField,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> options,
    required void Function(T?) onChanged,
    required String Function(T) displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppReusableText(
          text: label,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        const Gap(6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputField,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.inputField,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: options.map((T option) {
                return DropdownMenuItem<T>(
                  value: option,
                  child: Text(
                    displayText(option).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleField({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppReusableText(
                text: label,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              if (subtitle != null) ...[
                const Gap(2),
                AppReusableText(
                  text: subtitle,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withOpacity(0.3),
          inactiveThumbColor: AppColors.greyB3,
          inactiveTrackColor: AppColors.greyB3.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Product Images '),
        AppReusableText(
          text: 'Add up to 5 images',
          fontSize: 11,
          color: AppColors.textSecondary.withOpacity(0.7),
        ),
        const Gap(12),
        
        // Show existing images (from server)
        if (_existingImageUrls.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _existingImageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeExistingImage(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const Gap(12),
        ],
        
        // Show newly selected images
        if (_selectedImages.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeNewImage(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const Gap(12),
        ],
        
        // Add Images button
        if (totalImages < 5)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.inputField,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const Gap(6),
                  AppReusableText(
                    text: 'Add Images',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading when fetching product data in edit mode
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: SharedAppbar(title: _isEditMode ? 'Edit Product' : 'Create Product'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const Gap(16),
              AppReusableText(
                text: 'Fetching data...',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: SharedAppbar(title: _isEditMode ? 'Edit Product' : 'Create Product'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information
                _buildSectionCard(
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildInputField(
                      label: 'Product Name',
                      controller: _nameController,
                      hintText: 'Enter Product Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    _buildInputField(
                      label: 'Description',
                      controller: _descriptionController,
                      hintText: 'Enter product description',
                      maxLines: 4,
                    ),
                    const Gap(16),
                    _buildInputField(
                      label: 'Short Description',
                      controller: _shortDescriptionController,
                      hintText: 'Enter short description',
                      maxLines: 2,
                    ),
                    const Gap(16),
                    _buildDropdownField<String>(
                      label: 'Status',
                      value: _status,
                      options: _statusOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                      displayText: (s) => s,
                    ),
                  ],
                ),
                const Gap(16),

                // Product Images
                _buildSectionCard(
                  children: [_buildImageSection()],
                ),
                const Gap(16),

                // Pricing
                _buildSectionCard(
                  children: [
                    _buildSectionTitle('Pricing'),
                    _buildInputField(
                      label: 'Regular Price *',
                      controller: _regularPriceController,
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        return null;
                      },
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: AppReusableText(
                            text: '\$',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                    _buildInputField(
                      label: 'Sale Price (Optional)',
                      controller: _salePriceController,
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: AppReusableText(
                            text: '\$',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Inventory
                _buildSectionCard(
                  children: [
                    _buildSectionTitle('Inventory'),
                    _buildInputField(
                      label: 'SKU (Optional)',
                      controller: _skuController,
                      hintText: 'Enter SKU',
                    ),
                    const Gap(16),
                    _buildDropdownField<String>(
                      label: 'Stock Status',
                      value: _stockStatus,
                      options: _stockStatusOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _stockStatus = value);
                        }
                      },
                      displayText: (s) => s.replaceAll('onbackorder', 'on backorder'),
                    ),
                    const Gap(16),
                    _buildToggleField(
                      label: 'Manage Stock',
                      value: _manageStock,
                      onChanged: (value) => setState(() => _manageStock = value),
                    ),
                  ],
                ),
                const Gap(16),

                // Shipping
                _buildSectionCard(
                  children: [
                    _buildSectionTitle('Shipping'),
                    _buildInputField(
                      label: 'Weight (Optional)',
                      controller: _weightController,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: AppReusableText(
                            text: 'kg',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                    AppReusableText(
                      text: 'Dimensions (Optional)',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Length',
                            controller: _lengthController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _buildInputField(
                            label: 'Width',
                            controller: _widthController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _buildInputField(
                            label: 'Height',
                            controller: _heightController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),

                // Advanced
                _buildSectionCard(
                  children: [
                    _buildSectionTitle('Advanced'),
                    _buildDropdownField<String>(
                      label: 'Product Type',
                      value: _productType,
                      options: _productTypeOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _productType = value);
                        }
                      },
                      displayText: (s) => s[0].toUpperCase() + s.substring(1),
                    ),
                    const Gap(16),
                    _buildToggleField(
                      label: 'Virtual Product',
                      subtitle: 'Virtual products are not shipped',
                      value: _virtual,
                      onChanged: (value) => setState(() => _virtual = value),
                    ),
                    const Divider(height: 24, color: Color(0xFF2D3748)),
                    _buildToggleField(
                      label: 'Downloadable Product',
                      subtitle: 'Downloadable products give access to a file upon purchase',
                      value: _downloadable,
                      onChanged: (value) => setState(() => _downloadable = value),
                    ),
                  ],
                ),
                const Gap(24),

                // Create/Update Product Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                      final isLoading = state is ProductLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Update Product' : 'Create Product',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                ),
                const Gap(32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
