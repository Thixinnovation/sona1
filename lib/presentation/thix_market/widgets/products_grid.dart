import 'package:flutter/material.dart';
import '../../../models/product.dart';
import 'product_card.dart';

class ProductsGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final int crossAxisCount;
  final double childAspectRatio;

  const ProductsGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucun produit trouvé', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onTap: () => onProductTap(products[index]),
      ),
    );
  }
}
