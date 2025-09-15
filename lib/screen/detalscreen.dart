import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerceapp/screen/Home.dart'; // Import Home.dart to access the Product class
import 'package:ecommerceapp/screen/Cartscreen.dart'; // Import Cartscreen
import 'package:flutter_animate/flutter_animate.dart';

import '../productmodels.dart';

class Detalscreen extends StatefulWidget {
  final Product product;

  const Detalscreen({super.key, required this.product});

  @override
  State<Detalscreen> createState() => _DetalscreenState();
}

class _DetalscreenState extends State<Detalscreen> {
  int selectedColorIndex = 0;
  List<String> shoeImages = [];
  int? selectedSizeIndex;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    // Initialize shoeImages with image1 and image2 from Firestore
    shoeImages = [
      widget.product.imagePath,
      widget.product.secondaryImagePath ?? widget.product.imagePath,
    ];
    // Check if the product is in the favourites collection
    checkFavoriteStatus();
  }

  Future<void> checkFavoriteStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('favourites')
          .doc(widget.product.name)
          .get();
      setState(() {
        isFavorited = doc.exists;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking favorite status: $e')),
      );
    }
  }

  Future<void> toggleFavorite() async {
    try {
      if (isFavorited) {
        await FirebaseFirestore.instance
            .collection('favourites')
            .doc(widget.product.name)
            .delete();
        setState(() {
          isFavorited = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} removed from favorites')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('favourites')
            .doc(widget.product.name)
            .set(widget.product.toMap());
        setState(() {
          isFavorited = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} added to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite: $e')),
      );
    }
  }

  Future<void> addToCart() async {
    if (selectedSizeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a size')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cart').add({
        'name': widget.product.name,
        'price': widget.product.price,
        'imagePath': shoeImages[selectedColorIndex],
        'quantity': 1,
        'size': [5, 6, 7, 8, 9, 10][selectedSizeIndex!],
        'colorIndex': selectedColorIndex,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Cartscreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access current theme
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware background
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: theme.colorScheme.surface, // Replace hardcoded color with theme
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
            ),
          ),
          Positioned(
            top: 80,
            left: 35,
            child: Row(
              children: [
                Text(
                  widget.product.name,
                  style: GoogleFonts.anton(
                    fontSize: 24,
                    color: theme.textTheme.titleLarge?.color, // Theme-aware text
                  ),
                ),
                const SizedBox(width: 100),
                GestureDetector(
                  onTap: toggleFavorite,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: MediaQuery.of(context).size.width * 0.16,
                    height: MediaQuery.of(context).size.height * 0.07,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black, // Theme-aware color
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_outline,
                      size: 26,
                      color: theme.colorScheme.primary, // Theme-aware icon color
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 135,
            left: 35,
            child: Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.secondary, size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.product.rating?.toStringAsFixed(1) ?? 'N/A',
                  style: GoogleFonts.aclonica(
                    fontSize: 18,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Reviews",
                  style: GoogleFonts.alegreya(
                    fontSize: 18,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 180,
            left: 19,
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      widget.product.price != null
                          ? "\Rs ${widget.product.price!.toStringAsFixed(0)}"
                          : 'N/A',
                      style: GoogleFonts.anton(
                        fontSize: 32,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      "2 Color",
                      style: GoogleFonts.alegreya(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorIndex = 0;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            elevation: 5,
                            borderRadius: const BorderRadius.all(Radius.circular(40)),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.27,
                              height: MediaQuery.of(context).size.height * 0.15,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.all(Radius.circular(40)),
                                border: Border.all(
                                  color: selectedColorIndex == 0
                                      ? theme.colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 25,
                            child: Image.network(
                              shoeImages[0],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: theme.colorScheme.errorContainer,
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorIndex = 1;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            elevation: 5,
                            borderRadius: const BorderRadius.all(Radius.circular(40)),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.27,
                              height: MediaQuery.of(context).size.height * 0.15,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: const BorderRadius.all(Radius.circular(40)),
                                border: Border.all(
                                  color: selectedColorIndex == 1
                                      ? theme.colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 20,
                            child: Image.network(
                              shoeImages[1],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: theme.colorScheme.errorContainer,
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 25),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      elevation: 5,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        bottomLeft: Radius.circular(50),
                      ),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(50),
                            bottomLeft: Radius.circular(50),
                          ),
                          color: theme.colorScheme.surfaceVariant,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -15,
                      top: -60,
                      child: Image.network(
                        shoeImages[selectedColorIndex],
                        height: 200,
                        fit: BoxFit.contain,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: theme.colorScheme.errorContainer,
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 600.ms).slideY(
              begin: 0.3,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOut,
            ),
          ),
          Positioned(
            top: 580,
            left: 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    "Sizes",
                    style: GoogleFonts.aboreto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 5),
                  ...[6, 7, 8, 9, 10].asMap().entries.map((entry) {
                    final index = entry.key;
                    final size = entry.value;
                    return SizeButton(
                      size: size,
                      isSelected: selectedSizeIndex == index,
                      onTap: () {
                        setState(() {
                          selectedSizeIndex = index;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 653,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.15,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(45),
                  topLeft: Radius.circular(45),
                ),
                color: theme.colorScheme.onSurface, // Theme-aware bottom bar
              ),
              child: Row(
                children: [
                  const Image(image: AssetImage("assets/images/360.png")),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.height * 0.1,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(35)),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: GestureDetector(
                        onTap: addToCart,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "add to bag",
                                style: GoogleFonts.alexandria(
                                  fontSize: 22,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(
              begin: 0.3,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }
}

class SizeButton extends StatefulWidget {
  final int size;
  final bool isSelected;
  final VoidCallback onTap;

  const SizeButton({
    super.key,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SizeButton> createState() => _SizeButtonState();
}

class _SizeButtonState extends State<SizeButton> {
  bool _isBouncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBouncing = true;
        });
        widget.onTap();
      },
      child: Animate(
        effects: _isBouncing
            ? [
          ScaleEffect(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceOut,
          ),
        ]
            : [],
        onComplete: (_) => setState(() => _isBouncing = false),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.06,
          width: MediaQuery.of(context).size.width * 0.12,
          margin: const EdgeInsets.only(right: 13),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: widget.isSelected ? null : theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: theme.colorScheme.surface.withOpacity(0.7),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${widget.size}',
              style: GoogleFonts.alegreya(
                fontSize: 20,
                color: widget.isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}