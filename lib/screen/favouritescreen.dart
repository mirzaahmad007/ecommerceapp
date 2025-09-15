import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../productmodels.dart';
import 'detalscreen.dart';
import 'Home.dart';

class Favouritescreen extends StatefulWidget {
  const Favouritescreen({super.key});

  @override
  State<Favouritescreen> createState() => _FavouritescreenState();
}

class _FavouritescreenState extends State<Favouritescreen> {
  List<Product> favoriteProducts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchFavoriteProducts();
  }

  Future<void> fetchFavoriteProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('favourites').get();
      setState(() {
        favoriteProducts = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load favorites. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage!,
            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 10,
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : errorMessage != null
            ? Center(
          child: Text(
            errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: theme.shadowColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        )
            : favoriteProducts.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 0.1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, angle, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'No favorites yet',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: theme.shadowColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 50, left: 20),
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                        BoxShadow(
                          color: theme.colorScheme.surface.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50, top: 50),
                  child: Text(
                    "Favourites",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: theme.textTheme.titleLarge?.color,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: theme.shadowColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: favoriteProducts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: buildFavoriteProductContainer(context, favoriteProducts[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFavoriteProductContainer(BuildContext context, Product product) {
    bool isTapped = false;
    bool isDeleteTapped = false;
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isTapped = true),
          onTapUp: (_) {
            setState(() => isTapped = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Detalscreen(product: product),
              ),
            );
          },
          onTapCancel: () => setState(() => isTapped = false),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 1.0, end: isTapped ? 0.95 : 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, scale, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateX(0.15)
                  ..rotateY(-0.15)
                  ..scale(scale),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Material(
              elevation: 15,
              borderRadius: BorderRadius.circular(25),
              shadowColor: theme.shadowColor,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? theme.cardColor : null,
                  gradient: theme.brightness == Brightness.dark
                      ? LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(5, 5),
                    ),
                    BoxShadow(
                      color: theme.colorScheme.surface.withOpacity(0.1),
                      blurRadius: 12,
                      offset: Offset(-5, -5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(0.25),
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: theme.colorScheme.surfaceVariant,
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(3, 3),
                            ),
                            BoxShadow(
                              color: theme.colorScheme.surface.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(-3, -3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              product.imagePath,
                              width: MediaQuery.of(context).size.width * 0.35,
                              height: MediaQuery.of(context).size.height * 0.18,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.height * 0.18,
                                  color: theme.colorScheme.errorContainer,
                                  child: Center(
                                    child: Icon(Icons.error, color: theme.colorScheme.onError),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.price != null ? "\$${product.price!.toStringAsFixed(2)}" : 'N/A',
                                style: GoogleFonts.poppins(
                                  color: theme.brightness == Brightness.light
                                      ? theme.textTheme.bodyMedium?.color
                                      : theme.colorScheme.onPrimary.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: theme.shadowColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                product.name,
                                style: GoogleFonts.poppins(
                                  color: theme.brightness == Brightness.light
                                      ? theme.textTheme.bodyLarge?.color
                                      : theme.colorScheme.onPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: theme.shadowColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(3, 3),
                                    ),
                                    BoxShadow(
                                      color: theme.colorScheme.surface.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(-3, -3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  color: theme.colorScheme.error,
                                  size: 26,
                                ),
                              ),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTapDown: (_) => setState(() => isDeleteTapped = true),
                                onTapUp: (_) async {
                                  setState(() => isDeleteTapped = false);
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('favourites')
                                        .doc(product.id ?? product.name)
                                        .delete();
                                    setState(() {
                                      favoriteProducts.remove(product);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} removed from favorites',
                                          style: GoogleFonts.poppins(color: theme.colorScheme.onPrimaryContainer),
                                        ),
                                        backgroundColor: theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        behavior: SnackBarBehavior.floating,
                                        elevation: 10,
                                        margin: const EdgeInsets.all(10),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to remove ${product.name} from favorites. Please try again.',
                                          style: GoogleFonts.poppins(color: theme.colorScheme.onError),
                                        ),
                                        backgroundColor: theme.colorScheme.error,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        behavior: SnackBarBehavior.floating,
                                        elevation: 10,
                                        margin: const EdgeInsets.all(10),
                                      ),
                                    );
                                  }
                                },
                                onTapCancel: () => setState(() => isDeleteTapped = false),
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 1.0, end: isDeleteTapped ? 0.9 : 1.0),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (context, scale, child) {
                                    return Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.002)
                                        ..scale(scale),
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.surface,
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.shadowColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(3, 3),
                                            ),
                                            BoxShadow(
                                              color: theme.colorScheme.surface.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: Offset(-3, -3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.delete,
                                          color: theme.colorScheme.error,
                                          size: 26,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}