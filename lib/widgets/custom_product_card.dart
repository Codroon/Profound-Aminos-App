import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/shared_dynamic_icon.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final String category;
  final String price;
  final String? stockStatus;
  final Color? stockStatusColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? subtitleColor;
  final dynamic productIcon;
  final Color? productIconColor;
  final List<ActionButton> actionButtons;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double elevation;

  ProductCard({
    super.key,
    required this.productName,
    required this.category,
    required this.price,
    this.stockStatus,
    this.stockStatusColor,
    this.backgroundColor,
    this.textColor,
    this.subtitleColor,
    this.productIcon = Icons.shopping_bag_outlined,
    this.productIconColor,
    this.actionButtons = const [],
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: backgroundColor ?? AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              // Product Icon
              Container(
                width: 78,
                height: 80,
                decoration: BoxDecoration(
                  color: (productIconColor ?? AppColors.secondary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SharedDynamicIcon(
                  productIcon,
                  color: productIconColor ?? AppColors.secondary,
                  weight: 71,
                  height: 71,
                ),
              ),
              Gap(10),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name and Stock Status Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productName,
                            style: TextStyle(
                              color: textColor ?? AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (stockStatus != null) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: stockStatusColor ?? AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              stockStatus!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    // Category
                    Text(
                      'Category: $category',
                      style: TextStyle(
                        color: subtitleColor ?? AppColors.greyB3,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    // Price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Price: $price',
                            style: TextStyle(
                              color: subtitleColor ?? AppColors.greyB3,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        // Action Buttons
                        if (actionButtons.isNotEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.delete,
                                  size: 24,
                                  color: AppColors.greyB3,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.edit_note,
                                  size: 24,
                                  color: AppColors.greyB3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButton {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  const ActionButton({
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onPressed,
    this.tooltip,
    this.size = 32,
  });
}

// Example Usage Widget
class ProductCardExample extends StatelessWidget {
  const ProductCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Product Cards'),
        backgroundColor: const Color(0xFF2D2D3F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Original Design
            ProductCard(
              productName: 'Baza',
              category: 'Bags',
              price: '\$15.00',
              stockStatus: 'Out of Stock',
              stockStatusColor: Colors.red,
              actionButtons: [
                ActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  onPressed: () => print('Delete pressed'),
                ),
                ActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  onPressed: () => print('Edit pressed'),
                ),
              ],
              onTap: () => print('Product tapped'),
            ),

            const SizedBox(height: 16),

            // Variation with In Stock
            ProductCard(
              productName: 'Laptop Pro',
              category: 'Electronics',
              price: '\$999.00',
              stockStatus: 'In Stock',
              stockStatusColor: Colors.green,
              productIcon: Icons.laptop_mac_outlined,
              productIconColor: Colors.blue,
              actionButtons: [
                ActionButton(
                  icon: Icons.favorite_outline,
                  tooltip: 'Add to Wishlist',
                  onPressed: () => print('Wishlist pressed'),
                ),
                ActionButton(
                  icon: Icons.shopping_cart_outlined,
                  tooltip: 'Add to Cart',
                  onPressed: () => print('Cart pressed'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Without Stock Status
            ProductCard(
              productName: 'Coffee Mug',
              category: 'Kitchen',
              price: '\$12.99',
              productIcon: Icons.coffee_outlined,
              productIconColor: Colors.brown,
              actionButtons: [
                ActionButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Share',
                  onPressed: () => print('Share pressed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
