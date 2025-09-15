import 'package:ecommerceapp/screen/setting.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../paymentwalletscreen.dart';
import '../productmodels.dart';
import '../thme/helpsupport.dart';
import 'cartscreen.dart';
import 'category.dart';
import 'detalscreen.dart';
import 'favouritescreen.dart';
import 'logiin.dart';
import 'login.dart';
import 'ordersscreen.dart';
import 'profilescreen.dart';
import '../models/product.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isNotificationsEnabled = true;
  bool _isPrivacyEnabled = false;
  TextEditingController textEditingController = TextEditingController();
  String selectedCategory = 'Sneakers';
  GlobalKey sneakerKey = GlobalKey();
  GlobalKey sportsKey = GlobalKey();
  double lineWidth = 0.0;
  double lineOffset = 0.0;
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  Set<String> favoriteProductIds = {};
  String _userName = "Guest";
  String _email = "guest@example.com";
  String _imageUrl = "https://res.cloudinary.com/dpfebhnli/image/upload/v1742469623/gazatube_nxu2k8.jpg";
  bool _isProfileLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchFavorites();
    fetchProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateLinePosition();
    });
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching products: $e')),
        );
      }
    }
  }

  Future<double?> calculateAverageRating(String productId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('productId', isEqualTo: productId)
          .get();
      if (snapshot.docs.isEmpty) return null;
      double totalRating = 0;
      int count = 0;
      for (var doc in snapshot.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble();
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }
      return count > 0 ? totalRating / count : null;
    } catch (e) {
      print('Error calculating average rating for $productId: $e');
      return null;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching favorites: $e')),
        );
      }
    }
  }

  Future<void> fetchProfileData() async {
    setState(() => _isProfileLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, using default profile values');
        setState(() {
          _userName = "Guest";
          _email = "guest@example.com";
          _imageUrl = "https://res.cloudinary.com/dpfebhnli/image/upload/v1742469623/gazatube_nxu2k8.jpg";
          _isProfileLoading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('profile')
          .doc(user.uid)
          .get();
      setState(() {
        if (doc.exists) {
          _userName = doc.data()?['userName'] ?? "Guest";
          _email = doc.data()?['email'] ?? "guest@example.com";
          _imageUrl = doc.data()?['imageUrl'] ?? _imageUrl;
          _isNotificationsEnabled = doc.data()?['settings']?['isNotificationsEnabled'] ?? true;
          _isPrivacyEnabled = doc.data()?['settings']?['isPrivacyEnabled'] ?? false;
        }
        _isProfileLoading = false;
      });
    } catch (e) {
      print('Error fetching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
      setState(() => _isProfileLoading = false);
    }
  }

  void updateLinePosition() {
    final shoesRenderBox = sneakerKey.currentContext?.findRenderObject() as RenderBox?;
    final clothesRenderBox = sportsKey.currentContext?.findRenderObject() as RenderBox?;
    if (shoesRenderBox != null && clothesRenderBox != null) {
      final shoesSize = shoesRenderBox.size;
      final clothesSize = clothesRenderBox.size;
      final shoesOffset = shoesRenderBox.localToGlobal(Offset.zero).dx;
      final clothesOffset = clothesRenderBox.localToGlobal(Offset.zero).dx;
      setState(() {
        if (selectedCategory == 'Sneakers') {
          lineWidth = shoesSize.width;
          lineOffset = shoesOffset;
        } else {
          lineWidth = clothesSize.width;
          lineOffset = clothesOffset;
        }
      });
    }
  }

  void _onLanguageChanged(String newLanguage) async {
    // Removed localization-related updates
  }

  void _onNotificationChanged(bool isEnabled) async {
    setState(() {
      _isNotificationsEnabled = isEnabled;
    });
    print('Notifications toggled: $isEnabled');
  }

  void _onPrivacyChanged(bool isEnabled) async {
    setState(() {
      _isPrivacyEnabled = isEnabled;
    });
    print('Privacy toggled: $isEnabled');
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} removed from favorites')),
          );
        }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} added to favorites')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final filteredProducts = products
        .where((product) =>
    product.category == selectedCategory &&
        product.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image(
              image: const AssetImage("assets/images/niko.png"),
              color: isDarkMode ? Colors.orange[300] : Colors.orange,
              width: 60,
              height: 60,
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, size: 24, color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.26),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isProfileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [Colors.grey[800]!, Colors.grey[700]!]
                                : [theme.primaryColor.withOpacity(0.8), theme.colorScheme.secondary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black.withOpacity(0.5) : theme.shadowColor.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                          backgroundColor: isDarkMode ? Colors.grey[800] : theme.colorScheme.surface,
                          child: _imageUrl.isEmpty
                              ? Icon(Icons.person, size: 50, color: isDarkMode ? Colors.white70 : theme.iconTheme.color)
                              : null,
                        ).animate().scale(duration: 600.ms, curve: Curves.easeInOut).fadeIn(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : theme.textTheme.titleLarge?.color,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 6),
                  Text(
                    _email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  if (_isPrivacyEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Private',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.red[300] : theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.home,
                    title: "Home",
                    onTap: () => Navigator.pop(context),
                    delay: 400.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.favorite,
                    title: "Favorites",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Favouritescreen()),
                      );
                    },
                    delay: 450.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.shopping_cart,
                    title: "Cart",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Cartscreen()),
                      );
                    },
                    delay: 500.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.person,
                    title: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(isPrivacyEnabled: _isPrivacyEnabled),
                        ),
                      );
                    },
                    delay: 550.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.shopping_bag,
                    title: "Orders",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Ordersscreen()),
                      );
                    },
                    delay: 600.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.payment,
                    title: "Payment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Paymentwalletscreen()));
                    },
                    delay: 650.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Setting(
                            onPrivacyChanged: _onPrivacyChanged,
                            isPrivacyEnabled: _isPrivacyEnabled,
                          ),
                        ),
                      );
                    },
                    delay: 700.ms,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.help,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Helpsupport(
                            onPrivacyChanged: _onPrivacyChanged,
                            isPrivacyEnabled: _isPrivacyEnabled,
                          ),
                        ),
                      );
                    },
                    delay: 750.ms,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout, color: isDarkMode ? Colors.white : theme.colorScheme.onError),
                label: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : theme.colorScheme.onError,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.red[700] : theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 5,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ).animate().fadeIn(delay: 800.ms),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!, style: TextStyle(color: isDarkMode ? Colors.red[300] : theme.colorScheme.error)))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 10),
              child: Text(
                "Collections",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : theme.textTheme.titleLarge?.color,
                ),
              ).animate().fadeIn(duration: 500.ms),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = 'Sneakers';
                            updateLinePosition();
                          });
                        },
                        child: Text(
                          "Sneakers",
                          key: sneakerKey,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            color: selectedCategory == 'Sneakers'
                                ? (isDarkMode ? Colors.white : theme.colorScheme.primary)
                                : (isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color),
                            fontSize: 12,
                            decoration: selectedCategory == 'Sneakers' ? TextDecoration.none : null,
                            decorationColor: isDarkMode ? Colors.white : theme.colorScheme.primary,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = 'Sports Shoes';
                            updateLinePosition();
                          });
                        },
                        child: Text(
                          "Sports Shoes",
                          key: sportsKey,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            color: selectedCategory == 'Sports Shoes'
                                ? (isDarkMode ? Colors.white : theme.colorScheme.primary)
                                : (isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color),
                            fontSize: 12,
                            decoration: selectedCategory == 'Sports Shoes' ? TextDecoration.none : null,
                            decorationColor: isDarkMode ? Colors.white : theme.colorScheme.primary,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Category(),
                            ),
                          );
                        },
                        child: Image(
                          image: const AssetImage("assets/images/line2.png"),
                          color: isDarkMode ? Colors.orange[300] : Colors.orange,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 130,
                        height: 50,
                        child: TextFormField(
                          controller: textEditingController,
                          cursorColor: isDarkMode ? Colors.white : theme.colorScheme.primary,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search",
                            hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : theme.hintColor),
                            prefixIcon: Icon(Icons.search, size: 20, color: isDarkMode ? Colors.white70 : theme.iconTheme.color),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : theme.colorScheme.surface,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: isDarkMode ? Colors.white : theme.colorScheme.primary, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: lineWidth,
                    height: 3,
                    margin: EdgeInsets.only(left: lineOffset),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 40,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Transform.translate(
                        offset: Offset(0, index % 2 == 0 ? 0 : 50),
                        child: ProductCard(
                          product: product,
                          isFavorited: favoriteProductIds.contains(product.productId),
                          onFavoriteToggle: (product) => toggleFavorite(product.productId, product),
                        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        required Duration delay,
      }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey[700]! : theme.dividerColor)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white70 : theme.iconTheme.color, size: 28),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
        onTap: onTap,
        hoverColor: isDarkMode ? Colors.grey[800] : theme.hoverColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      ).animate().slideX(
        begin: -0.2,
        end: 0,
        duration: 600.ms,
        delay: delay,
        curve: Curves.easeInOut,
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

  Future<double?> calculateAverageRating(String productId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('productId', isEqualTo: productId)
          .get();
      if (snapshot.docs.isEmpty) return null;
      double totalRating = 0;
      int count = 0;
      for (var doc in snapshot.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble();
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }
      return count > 0 ? totalRating / count : null;
    } catch (e) {
      print('Error calculating average rating for $productId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
                            FutureBuilder<double?>(
                              future: calculateAverageRating(widget.product.productId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Text(
                                    'N/A',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "Poppins",
                                      color: isDarkMode ? Colors.white70 : theme.textTheme.bodySmall?.color,
                                    ),
                                  );
                                }
                                final rating = snapshot.data!;
                                return Row(
                                  children: [
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: "Poppins",
                                        color: isDarkMode ? Colors.white70 : theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                  ],
                                );
                              },
                            ),
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
                            color: isDarkMode ? Colors.grey[700] : theme.colorScheme.errorContainer,
                            child: Center(
                              child: Icon(
                                Icons.error,
                                color: isDarkMode ? Colors.white70 : theme.iconTheme.color,
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
                        style: GoogleFonts.poppins(
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
                        color: isDarkMode ? Colors.white : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black.withOpacity(0.4) : theme.shadowColor.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isDarkMode ? Colors.red[300] : theme.colorScheme.primary,
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
                      fontSize: 16,
                      fontFamily: "Poppins",
                      color: isDarkMode ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (discountedPrice != null) ...[
                        Text(
                          '\Rs ${originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: "Poppins",
                            color: isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\Rs ${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Poppins",
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          originalPrice != null ? '\Rs ${originalPrice.toStringAsFixed(0)}' : 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Poppins",
                            color: isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color,
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