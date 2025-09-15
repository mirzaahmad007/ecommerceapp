import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Ordersscreen extends StatefulWidget {
  const Ordersscreen({super.key});

  @override
  State<Ordersscreen> createState() => _OrdersscreenState();
}

class _OrdersscreenState extends State<Ordersscreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _hiddenOrderIds = {}; // Track hidden orders locally

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Show rating dialog for Delivered orders
  Future<void> _showRatingDialog(String orderId, double currentRating) async {
    final theme = Theme.of(context);
    double rating = currentRating;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor.withOpacity(0.95),
        title: Text('Rate Order #$orderId', style: GoogleFonts.aclonica(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Rating: ${rating.toStringAsFixed(1)}',
              style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: rating,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: theme.colorScheme.primary,
              ),
              onRatingUpdate: (value) {
                rating = value;
              },
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
                  'rating': rating,
                });
                setState(() {
                  _hiddenOrderIds.add(orderId); // Hide order from Delivered tab
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rating updated to $rating stars', style: TextStyle(color: theme.colorScheme.onSurface))),
                );
                Navigator.pop(context);
              } catch (e) {
                String errorMessage = 'Error updating rating';
                if (e is FirebaseException) {
                  if (e.code == 'permission-denied') {
                    errorMessage = 'Permission denied. Please check your access rights.';
                  } else if (e.code == 'unavailable') {
                    errorMessage = 'Network error. Please check your connection.';
                  } else if (e.code == 'not-found') {
                    errorMessage = 'Order not found';
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$errorMessage: $e', style: TextStyle(color: theme.colorScheme.onError))),
                );
              }
            },
            child: Text('Submit', style: GoogleFonts.alegreya(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms),
    );
  }

  // Show confirmation dialog for deleting an order
  Future<bool> _showDeleteConfirmationDialog(String orderId) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor.withOpacity(0.95),
        title: Text('Delete Order #$orderId', style: GoogleFonts.aclonica(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        content: Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
          style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.alegreya(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms),
    ) ?? false;
  }

  // Delete order from Firestore
  Future<void> _deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('Orders').doc(orderId).delete();
      setState(() {
        _hiddenOrderIds.add(orderId); // Hide order immediately
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId deleted')),
      );
    } catch (e) {
      String errorMessage = 'Error deleting order';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errorMessage = 'Permission denied. Please check your access rights.';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.code == 'not-found') {
          errorMessage = 'Order not found';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: $e')),
      );
    }
  }

  // Widget to display orders for a specific status
  Widget _buildOrderList(String status) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Text(
          'Please log in to view orders',
          style: GoogleFonts.alegreya(fontSize: 18, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        ).animate().fadeIn(delay: 300.ms),
      );
    }

    print('Querying for userId: $userId, status: $status'); // Debug log
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }
        if (snapshot.hasError) {
          String errorMessage = 'Error fetching orders';
          if (snapshot.error is FirebaseException) {
            final error = snapshot.error as FirebaseException;
            if (error.code == 'permission-denied') {
              errorMessage = 'Permission denied. Please check your access rights.';
            } else if (error.code == 'unavailable') {
              errorMessage = 'Network error. Please check your connection.';
            } else if (error.code == 'failed-precondition') {
              errorMessage = 'Missing index. Please create a composite index on userId, status, and orderDate.';
            }
          }
          return Center(
            child: Text(
              '$errorMessage: ${snapshot.error}',
              style: GoogleFonts.alegreya(fontSize: 16, color: theme.colorScheme.error),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status orders found',
              style: GoogleFonts.alegreya(fontSize: 18, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
            ).animate().fadeIn(delay: 300.ms),
          );
        }

        final orders = snapshot.data!.docs.where((order) {
          final orderData = order.data();
          if (orderData == null) {
            print('Null order data for order ID: ${order.id}');
            return false;
          }
          final orderId = (orderData as Map<String, dynamic>)['orderId']?.toString() ?? order.id;
          return status != 'Delivered' || !_hiddenOrderIds.contains(orderId);
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No $status orders found',
              style: GoogleFonts.alegreya(fontSize: 18, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
            ).animate().fadeIn(delay: 300.ms),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderData = order.data() as Map<String, dynamic>?;
            if (orderData == null) {
              print('Skipping order with null data: ${order.id}');
              return const SizedBox.shrink();
            }

            final orderId = orderData['orderId']?.toString() ?? order.id;
            final total = orderData['totalWithDelivery']?.toStringAsFixed(2) ?? '0.00';
            final paymentMethod = orderData['paymentMethod']?.toString() ?? 'N/A';
            final items = orderData['items'] != null
                ? List<Map<String, dynamic>>.from(orderData['items'])
                : <Map<String, dynamic>>[];
            final orderDate = (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
            final rating = (orderData['rating'] as num?)?.toDouble() ?? 0.0;

            return Animate(
              key: ValueKey(orderId), // Unique key for animation
              effects: _hiddenOrderIds.contains(orderId)
                  ? [
                FadeEffect(
                  duration: 300.ms,
                  begin: 1.0,
                  end: 0.0,
                ),
                SlideEffect(
                  duration: 300.ms,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 0),
                  curve: Curves.easeOut,
                ),
              ]
                  : [],
              child: Card(
                elevation: 4,
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: GoogleFonts.aclonica(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ).animate().fadeIn(delay: 100.ms * index),
                      const SizedBox(height: 8),
                      Text(
                        'Total: $total PKR',
                        style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      Text(
                        'Payment: $paymentMethod',
                        style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      Text(
                        'Date: ${orderDate.toString().substring(0, 16)}',
                        style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Items:',
                        style: GoogleFonts.aclonica(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
                      ),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '- ${item['name'] ?? 'Item'} (Qty: ${item['quantity'] ?? 1})',
                          style: GoogleFonts.alegreya(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        ),
                      )),
                      const SizedBox(height: 12),
                      Text(
                        'Status: $status',
                        style: GoogleFonts.aclonica(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                      ),
                      if (status == 'Delivered') ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rating: ${rating.toStringAsFixed(1)}/5',
                              style: GoogleFonts.alegreya(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                            ).animate().fadeIn(delay: 100.ms * index).scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _showRatingDialog(orderId, rating),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(120, 36),
                                  ),
                                  child: Text(
                                    'Rate Order',
                                    style: GoogleFonts.aclonica(fontSize: 12, color: theme.colorScheme.onPrimary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final confirm = await _showDeleteConfirmationDialog(orderId);
                                    if (confirm) {
                                      await _deleteOrder(orderId);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surfaceVariant,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(120, 36),
                                  ),
                                  child: Text(
                                    'Delete Order',
                                    style: GoogleFonts.aclonica(fontSize: 12, color: theme.colorScheme.onPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: GoogleFonts.aclonica(fontSize: 18, color: theme.textTheme.titleLarge?.color),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            child: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onPrimary),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.aclonica(fontSize: 14, color: theme.colorScheme.primary),
          unselectedLabelStyle: GoogleFonts.alegreya(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Processing'),
            Tab(text: 'Dispatched'),
            Tab(text: 'Delivered'),
            Tab(text: 'Returned'),
          ],
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList('Processing'),
            _buildOrderList('Dispatched'),
            _buildOrderList('Delivered'),
            _buildOrderList('Returned'),
          ],
        ),
      ),
    );
  }
}