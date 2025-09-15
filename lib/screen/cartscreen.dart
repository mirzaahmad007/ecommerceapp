import 'package:ecommerceapp/screen/payment%20screen.dart';
import 'package:ecommerceapp/screen/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this import for animations

class Cartscreen extends StatefulWidget {
  const Cartscreen({super.key});

  @override
  State<Cartscreen> createState() => _CartscreenState();
}

class _CartscreenState extends State<Cartscreen> {
  Future<void> incrementQuantity(String docId, int currentQuantity) async {
    try {
      await FirebaseFirestore.instance.collection('cart').doc(docId).update({
        'quantity': currentQuantity + 1,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: $e', style: TextStyle(fontSize: 14 * (MediaQuery.of(context).size.width / 360)))),
      );
    }
  }

  Future<void> decrementQuantity(String docId, int currentQuantity) async {
    if (currentQuantity > 1) {
      try {
        await FirebaseFirestore.instance.collection('cart').doc(docId).update({
          'quantity': currentQuantity - 1,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e', style: TextStyle(fontSize: 14 * (MediaQuery.of(context).size.width / 360)))),
        );
      }
    } else {
      await deleteItem(docId);
    }
  }

  Future<void> deleteItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('cart').doc(docId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $e', style: TextStyle(fontSize: 14 * (MediaQuery.of(context).size.width / 360)))),
      );
    }
  }

  double calculateTotalPrice(List<QueryDocumentSnapshot> cartItems) {
    double itemsTotal = 0.0;
    for (var item in cartItems) {
      final data = item.data() as Map<String, dynamic>;
      final quantity = (data['quantity'] ?? 1).toDouble();
      final price = (data['price'] ?? 0.0).toDouble();
      itemsTotal += price * quantity;
    }
    return itemsTotal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 360;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 20 * scaleFactor),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8 * scaleFactor),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.26),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios, size: 20 * scaleFactor, color: theme.iconTheme.color),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.3),
                  Text(
                    " Cart",
                    style: GoogleFonts.aclonica(
                      fontSize: 24 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 20 * scaleFactor,
              color: theme.dividerColor,
              thickness: 1 * scaleFactor,
              indent: 16 * scaleFactor,
              endIndent: 16 * scaleFactor,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cart').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.alegreya(fontSize: 18 * scaleFactor, color: theme.colorScheme.error)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 100 * scaleFactor,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeInOut),
                          SizedBox(height: 20 * scaleFactor),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.aclonica(fontSize: 24 * scaleFactor, color: theme.textTheme.bodyLarge?.color),
                          ),
                          SizedBox(height: 10 * scaleFactor),
                          Text(
                            'Start adding items!',
                            style: GoogleFonts.alegreya(fontSize: 16 * scaleFactor, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                          ),
                          SizedBox(height: 20 * scaleFactor),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context), // Or navigate to home/shop
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor, vertical: 12 * scaleFactor),
                            ),
                            child: Text(
                              'Shop Now',
                              style: GoogleFonts.aclonica(fontSize: 16 * scaleFactor, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                    );
                  }

                  final cartItems = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 8 * scaleFactor),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final data = item.data() as Map<String, dynamic>;
                      final docId = item.id;
                      final quantity = data['quantity'] ?? 1;
                      final totalPrice = (data['price'] ?? 0.0) * quantity;

                      return Dismissible(
                        key: Key(docId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: EdgeInsets.symmetric(vertical: 8 * scaleFactor),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20 * scaleFactor),
                          child: Icon(Icons.delete, color: theme.colorScheme.onError, size: 30 * scaleFactor),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Remove Item', style: GoogleFonts.aclonica(fontSize: 20 * scaleFactor, color: theme.textTheme.titleMedium?.color)),
                              content: Text(
                                'Are you sure you want to remove ${data['name']} from your cart?',
                                style: GoogleFonts.alegreya(fontSize: 16 * scaleFactor, color: theme.textTheme.bodyMedium?.color),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: GoogleFonts.alegreya(fontSize: 14 * scaleFactor, color: theme.textTheme.bodyMedium?.color)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Remove', style: GoogleFonts.alegreya(color: theme.colorScheme.error, fontSize: 14 * scaleFactor)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          deleteItem(docId);
                        },
                        child: Card(
                          elevation: 4,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16 * scaleFactor))),
                          margin: EdgeInsets.symmetric(vertical: 8 * scaleFactor),
                          child: Padding(
                            padding: EdgeInsets.all(12 * scaleFactor),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: screenWidth * 0.25,
                                  height: screenWidth * 0.3,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    color: theme.colorScheme.surfaceVariant,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    child: Image.network(
                                      data['imagePath'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(child: Icon(Icons.error, color: theme.colorScheme.error, size: 24 * scaleFactor));
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16 * scaleFactor),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Item',
                                        style: GoogleFonts.aclonica(
                                          fontSize: 18 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      SizedBox(height: 4 * scaleFactor),
                                      Text(
                                        "Size: ${data['size'] ?? 'N/A'}",
                                        style: GoogleFonts.alegreya(fontSize: 14 * scaleFactor, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                      ),
                                      SizedBox(height: 4 * scaleFactor),
                                      Text(
                                        "\Rs ${totalPrice.toStringAsFixed(0)}",
                                        style: GoogleFonts.aclonica(fontSize: 16 * scaleFactor, color: theme.colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50 * scaleFactor,
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.light ? theme.colorScheme.primary : null,
                                    gradient: theme.brightness == Brightness.dark
                                        ? LinearGradient(
                                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                        : null,
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(0.26),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => incrementQuantity(docId, quantity),
                                        child: Padding(
                                          padding: EdgeInsets.all(8 * scaleFactor),
                                          child: Container(
                                            width: 36 * scaleFactor,
                                            height: 36 * scaleFactor,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                                            ),
                                            child: Icon(Icons.add, size: 20 * scaleFactor, color: theme.iconTheme.color),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8 * scaleFactor),
                                      Text(
                                        "$quantity",
                                        style: GoogleFonts.aboreto(
                                          fontSize: 18 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                          color: theme.brightness == Brightness.light ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 8 * scaleFactor),
                                      GestureDetector(
                                        onTap: () => decrementQuantity(docId, quantity),
                                        child: Padding(
                                          padding: EdgeInsets.all(8 * scaleFactor),
                                          child: Container(
                                            width: 36 * scaleFactor,
                                            height: 36 * scaleFactor,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                                            ),
                                            child: Icon(Icons.remove, size: 20 * scaleFactor, color: theme.iconTheme.color),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16 * scaleFactor),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.12),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cart').snapshots(),
                builder: (context, snapshot) {
                  double itemsTotal = 0.0;
                  if (snapshot.hasData) {
                    itemsTotal = calculateTotalPrice(snapshot.data!.docs);
                  }
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Subtotal: ${itemsTotal.toStringAsFixed(0)} PKR",
                                style: GoogleFonts.aclonica(
                                  fontSize: 12 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                "Delivery: 100 PKR (estimated)",
                                style: GoogleFonts.alegreya(fontSize: 10 * scaleFactor, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                "Total: ${(itemsTotal + 100).toStringAsFixed(0)} Rs",
                                style: GoogleFonts.aclonica(
                                  fontSize: 12 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    itemsTotal: itemsTotal,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12 * scaleFactor))),
                              padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor, vertical: 12 * scaleFactor),
                            ),
                            child: Text(
                              "Checkout",
                              style: GoogleFonts.alexandria(fontSize: 16 * scaleFactor, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * scaleFactor),
                      TextButton(
                        onPressed: () {
                          // Logic to clear cart
                          FirebaseFirestore.instance.collection('cart').get().then((snapshot) {
                            for (DocumentSnapshot doc in snapshot.docs) {
                              doc.reference.delete();
                            }
                          });
                        },
                        child: Text(
                          "Clear Cart",
                          style: GoogleFonts.alegreya(fontSize: 14 * scaleFactor, color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}