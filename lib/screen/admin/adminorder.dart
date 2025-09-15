import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderCheckScreen extends StatefulWidget {
  const AdminOrderCheckScreen({super.key});

  @override
  State<AdminOrderCheckScreen> createState() => _AdminOrderCheckScreenState();
}

class _AdminOrderCheckScreenState extends State<AdminOrderCheckScreen> {
  // Update order status in Firestore and handle deletion for "Delivered"
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        'statusUpdatedAt': Timestamp.now(),
      };
      // Add return timestamp if status is "Returned"
      if (newStatus == 'Returned') {
        updateData['returnRequestedAt'] = Timestamp.now();
      }
      await FirebaseFirestore.instance.collection('Orders').doc(orderId).update(updateData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $orderId updated to $newStatus')),
      );

      // No delete logic for "Delivered" here, as per requirement
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Order Management",
          style: GoogleFonts.aclonica(fontSize: 18),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red.shade400,
            ),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: GoogleFonts.alegreya()),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No orders found',
                style: GoogleFonts.alegreya(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs.where((doc) {
            final orderData = doc.data() as Map<String, dynamic>;
            final status = orderData['status'] ?? 'Processing';
            // Filter out "Delivered" orders to remove them from the screen
            return status != 'Delivered';
          }).toList();

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No pending orders found',
                style: GoogleFonts.alegreya(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;
              final orderId = orderData['orderId'] ?? 'Unknown';
              final customerName = orderData['name'] ?? 'N/A';
              final total = orderData['totalWithDelivery']?.toStringAsFixed(2) ?? '0.00';
              final paymentMethod = orderData['paymentMethod'] ?? 'N/A';
              final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
              final currentStatus = orderData['status'] ?? 'Processing';
              final orderDate = (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 4,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order $orderId',
                        style: GoogleFonts.aclonica(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer: $customerName',
                        style: GoogleFonts.alegreya(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        'Total: $total PKR',
                        style: GoogleFonts.alegreya(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        'Payment: $paymentMethod',
                        style: GoogleFonts.alegreya(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        'Date: ${orderDate.toString().substring(0, 16)}',
                        style: GoogleFonts.alegreya(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Items:',
                        style: GoogleFonts.aclonica(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '- ${item['name'] ?? 'Item'} (Qty: ${item['quantity'] ?? 1})',
                          style: GoogleFonts.alegreya(fontSize: 14, color: Colors.grey[700]),
                        ),
                      )),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: $currentStatus',
                            style: GoogleFonts.aclonica(fontSize: 16, color: Colors.black87),
                          ),
                          DropdownButton<String>(
                            value: currentStatus,
                            items: ['Processing', 'Dispatched', 'Delivered', 'Returned']
                                .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status, style: GoogleFonts.alegreya(fontSize: 14)),
                            ))
                                .toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null && newStatus != currentStatus) {
                                // Restrict "Returned" to "Delivered" orders
                                if (newStatus == 'Returned' && currentStatus != 'Delivered') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Returns are only allowed for Delivered orders')),
                                  );
                                  return;
                                }
                                _updateOrderStatus(orderId, newStatus);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}