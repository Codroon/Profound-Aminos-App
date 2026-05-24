import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/custom_button.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';
import '../widgets/product_card.dart';
import '../widgets/products_list_shimmer.dart';
import 'create_product_page.dart';

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
    // Load products when page is opened
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
      FetchProducts(page: _currentPage, perPage: 20, forceRefresh: true),
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
      FetchProducts(page: _currentPage, perPage: 20, forceRefresh: true),
    );
  }

  String _searchQuery = '';
  bool _isSearching = false;

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _allProducts.clear();
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      context.read<ProductBloc>().add(
        FetchProducts(page: _currentPage, perPage: 20, searchTerm: query, forceRefresh: true),
      );
    } else {
      _loadProducts(refresh: true);
    }
  }

  // Note: Product deletion is now handled directly in the ProductCard's onDelete callback
  // The confirmation dialog is shown by the Dismissible widget's confirmDismiss property

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background,
      appBar: SharedAppbar(
        title: 'All Products',

        actions: [
          IconButton(
            onPressed: () => _loadProducts(refresh: true),
            icon: Icon(Iconsax.refresh_outline),
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
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon:
                    _isSearching
                        ? Icon(Icons.search, color: AppColors.primary)
                        : const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isSearching ? AppColors.primary : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: _isSearching,
                fillColor:
                    _isSearching ? AppColors.primary.withOpacity(0.05) : null,
              ),
              onChanged: (value) {
                if (value.isEmpty && _searchQuery.isNotEmpty) {
                  _onSearch('');
                } else if (value.isNotEmpty && value.length >= 3) {
                  _onSearch(value);
                }
              },
              onSubmitted: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

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
                  return const ProductsListShimmer(itemCount: 8);
                }
                // Show loading indicator when searching
                if (state is ProductLoading &&
                    _isSearching &&
                    _searchQuery.isNotEmpty) {
                  return Column(
                    children: [
                      const ProductSearchShimmer(),
                      if (_allProducts.isNotEmpty)
                        Expanded(
                          child: Opacity(
                            opacity: 0.6,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _allProducts.length,
                              itemBuilder: (context, index) {
                                final product = _allProducts[index];
                                return ProductCard(
                                  product: product,
                                  onEdit: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateProductPage(product: product),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    // Immediately remove the product from the local list
                                    setState(() {
                                      _allProducts.removeAt(index);
                                    });
                                    // Then trigger the actual deletion in the backend
                                    context.read<ProductBloc>().add(DeleteProduct(product['id']));
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],
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
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: ProductsListShimmer(itemCount: 2),
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
                                (context) => CreateProductPage(product: product),
                          ),
                        );
                      },
                      onDelete: () {
                        // Immediately remove the product from the local list
                        setState(() {
                          _allProducts.removeAt(index);
                        });
                        // Then trigger the actual deletion in the backend
                        context.read<ProductBloc>().add(DeleteProduct(product['id']));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductPage()),
          );
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Add Product',
        child: const Icon(BoxIcons.bx_plus, color: Colors.white),
      ),
    );
  }
}
