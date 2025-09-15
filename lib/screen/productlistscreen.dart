import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ecommerceapp/models/product.dart';
import '../productmodels.dart';
import 'detalscreen.dart';

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  Set<String> favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchFavorites();
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: widget.category)
          .get();
      setState(() {
        products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load products: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('favourites')
          .doc(user.uid)
          .collection('items')
          .get();
      setState(() {
        favoriteProductIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching favorites: $e')),
      );
    }
  }

  Future<void> toggleFavorite(String productId, Product product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to manage favorites')),
        );
        return;
      }
      if (favoriteProductIds.contains(productId)) {
        await FirebaseFirestore.instance
            .collection('favourites')
            .doc(user.uid)
            .collection('items')
            .doc(productId)
            .delete();
        setState(() {
          favoriteProductIds.remove(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} removed from favorites')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('favourites')
            .doc(user.uid)
            .collection('items')
            .doc(productId)
            .set(product.toMap());
        setState(() {
          favoriteProductIds.add(productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} added to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: GoogleFonts.anton(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
          child: Text(
            errorMessage!,
            style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red),
          ),
        )
            : products.isEmpty
            ? Center(
          child: Text(
            'No products found in ${widget.category}',
            style: GoogleFonts.anton(
              fontSize: 20,
              color: isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
          ),
        )
            : SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 40,
                childAspectRatio: 0.6,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Transform.translate(
                  offset: Offset(0, index % 2 == 0 ? 0 : 50),
                  child: ProductCard(
                    product: product,
                    isFavorited: favoriteProductIds.contains(product.productId),
                    onFavoriteToggle: (product) => toggleFavorite(product.productId, product),
                  ).animate().fadeIn(delay: (index * 100).ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isFavorited;
  final Function(Product) onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorited,
    required this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isBouncing = false;
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final originalPrice = widget.product.price;
    final discount = widget.product.discountPercentage;
    final discountedPrice = originalPrice != null && discount != null && discount > 0
        ? originalPrice * (1 - discount / 100)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detalscreen(product: widget.product),
          ),
        );
      },
      child: Animate(
        effects: _isBouncing
            ? [
          ScaleEffect(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceOut,
          ),
        ]
            : [],
        onComplete: (_) => setState(() => _isBouncing = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [Colors.grey[800]!, Colors.grey[700]!]
                          : [Colors.grey[900]!, Colors.grey[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.product.rating != null
                                  ? widget.product.rating!.toStringAsFixed(1)
                                  : 'N/A',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.white,
                                fontSize: 14,
                                fontFamily: "Anton",
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.product.imagePath,
                        width: 110,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 150,
                            height: 150,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey,
                            child: Center(
                              child: Icon(
                                Icons.error,
                                color: isDarkMode ? Colors.white70 : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (discount != null && discount > 0) // Display discount badge
                  Positioned(
                    top: 165,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${discount.toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.anton(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(curve: Curves.easeInOut),
                    ),
                  ),
                Positioned(
                  top: 120,
                  right: 105,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBouncing = true;
                        _isFavorited = !_isFavorited;
                      });
                      widget.onFavoriteToggle(widget.product);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontFamily: "Anton",
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (discountedPrice != null) ...[
                        Text(
                          '\Rs ${originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black,
                            fontSize: 12,
                            fontFamily: "Anton",
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\Rs ${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontFamily: "Anton",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          originalPrice != null ? '\Rs ${originalPrice.toStringAsFixed(0)}' : 'N/A',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black,
                            fontSize: 14,
                            fontFamily: "Anton",
                          ),
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
    );
  }
}