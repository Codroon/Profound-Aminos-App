import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/custom_button.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';
import '../widgets/product_card.dart';
import 'create_product_page.dart';
import 'edit_product_page.dart';

class WooAllProductsPage extends StatefulWidget {
  const WooAllProductsPage({super.key});

  @override
  State<WooAllProductsPage> createState() => _WooAllProductsPageState();
}

class _WooAllProductsPageState extends State<WooAllProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  List<dynamic> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
      _allProducts.clear();
    }

    context.read<ProductBloc>().add(
      FetchProducts(page: _currentPage, perPage: 20),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    context.read<ProductBloc>().add(
      FetchProducts(page: _currentPage, perPage: 20),
    );
  }

  void _onSearch(String query) {
    // For now, we'll implement a simple local search
    // In a real app, you might want to implement server-side search
    setState(() {
      _currentPage = 1;
      _allProducts.clear();
    });
    _loadProducts(refresh: true);
  }

  void _showDeleteConfirmation(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ProductBloc>().add(DeleteProduct(product['id']));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppReusableText(
          text: 'All Products',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        // backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadProducts(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // Add Product Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Add New Product',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateProductPage(),
                    ),
                  );
                },
                // icon: Icons.add,
              ),
            ),
          ),

          const Gap(16),

          // Products List
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadProducts(refresh: true);
                } else if (state is ProductError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is ProductLoaded) {
                  setState(() {
                    if (_currentPage == 1) {
                      _allProducts = state.products;
                    } else {
                      _allProducts.addAll(state.products);
                    }
                    _isLoadingMore = false;
                  });
                }
              },
              builder: (context, state) {
                if (state is ProductLoading && _allProducts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is ProductError && _allProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const Gap(16),
                        AppReusableText(
                          text: state.message,
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        const Gap(16),
                        CustomButton(
                          text: 'Retry',
                          onPressed: () => _loadProducts(refresh: true),
                        ),
                      ],
                    ),
                  );
                }

                if (_allProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const Gap(16),
                        AppReusableText(
                          text: 'No products found',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        const Gap(16),
                        CustomButton(
                          text: 'Add First Product',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateProductPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _allProducts.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _allProducts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final product = _allProducts[index];
                    return ProductCard(
                      product: product,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditProductPage(product: product),
                          ),
                        );
                      },
                      onDelete: () => _showDeleteConfirmation(context, product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
