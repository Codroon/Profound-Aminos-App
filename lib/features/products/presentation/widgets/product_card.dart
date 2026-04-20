import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = product['name'] ?? 'Unknown Product';
    final String regularPrice = product['regular_price'] ?? '0';
    final String salePrice = product['sale_price'] ?? '';
    final String status = product['status'] ?? 'draft';
    final String stockStatus = product['stock_status'] ?? 'outofstock';
    final int stockQuantity = product['stock_quantity'] ?? 0;
    final String sku = product['sku'] ?? '';
    final List images = product['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0]['src'] ?? '' : '';

    return Dismissible(
      key: Key(product['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Product'),
              content: Text('Are you sure you want to delete "$name"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // Call the onDelete callback when confirmed
        onDelete();
        // The parent widget should immediately remove this item from the list
        // This is handled by the onDelete callback in WooAllProductsPage
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child:
                    imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 32,
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey[400],
                          size: 32,
                        ),
              ),

              Gap(16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppReusableText(
                      text: name,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                    ),
                    Gap(4),

                    // SKU
                    if (sku.isNotEmpty) ...[
                      AppReusableText(
                        text: 'SKU: $sku',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      Gap(4),
                    ],

                    // Price
                    Row(
                      children: [
                        if (salePrice.isNotEmpty && salePrice != '0') ...[
                          AppReusableText(
                            text: '\$$salePrice',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          Gap(8),
                          Text(
                            '\$$regularPrice',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else ...[
                          AppReusableText(
                            text: '\$$regularPrice',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    Gap(8),
                    Row(
                      children: [
                        _buildStatusChip(status),
                        Gap(8),
                        _buildStockChip(stockStatus, stockQuantity),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              IconButton(
                onPressed: onEdit,
                icon: Icon(Iconsax.edit_outline),
                color: AppColors.primary,
                tooltip: 'Edit Product',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'publish':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = 'Published';
        break;
      case 'draft':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        displayText = 'Draft';
        break;
      case 'private':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = 'Private';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppReusableText(
        text: displayText,
        fontSize: 8,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  Widget _buildStockChip(String stockStatus, int stockQuantity) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (stockStatus.toLowerCase()) {
      case 'instock':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = 'In Stock ($stockQuantity)';
        break;
      case 'outofstock':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        displayText = 'Out of Stock';
        break;
      case 'onbackorder':
        backgroundColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade700;
        displayText = 'Backorder';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = stockStatus.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppReusableText(
        text: displayText,
        fontSize: 8,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}
