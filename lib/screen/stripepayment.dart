import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripePaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String name;
  final String email;
  final String phone;
  final String address;

  const StripePaymentScreen({
    super.key,
    required this.totalAmount,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  Map<String, dynamic>? paymentIntent;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Use publishable key from .env
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE'];
    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception("Stripe publishable key is missing in .env");
    }

    Stripe.publishableKey = publishableKey;
    Stripe.instance.applySettings().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stripe init failed: $error")),
      );
    });
  }

  String _generateOrderId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return '#$number';
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 👇 Call your backend instead of Stripe API directly
      final response = await http.post(
        Uri.parse("https://YOUR_BACKEND_URL/create-payment-intent"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": (widget.totalAmount * 100).toInt(), // in paisa
          "currency": "PKR",
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to create PaymentIntent: ${response.body}");
      }

      paymentIntent = jsonDecode(response.body);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!["client_secret"],
          style: ThemeMode.dark,
          merchantDisplayName: 'Your Shop Name',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _saveOrderToFirestore(paymentIntent!["id"]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful!")),
      );
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: ${e.error.localizedMessage}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveOrderToFirestore(String paymentIntentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to place an order')),
        );
        return;
      }
      final userId = user.uid;
      final cartSnapshot = await FirebaseFirestore.instance.collection('cart').get();
      final cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();
      final orderId = _generateOrderId();

      await FirebaseFirestore.instance.collection('Orders').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'name': widget.name,
        'email': widget.email,
        'phone': widget.phone,
        'address': widget.address,
        'items': cartItems,
        'itemsTotal': widget.totalAmount - (cartSnapshot.docs.length * 250.0),
        'deliveryCharge': cartSnapshot.docs.length * 250.0,
        'totalWithDelivery': widget.totalAmount,
        'paymentMethod': 'Online Payment',
        'walletName': 'Stripe',
        'paymentIntentId': paymentIntentId,
        'orderDate': Timestamp.now(),
        'transactionId': paymentIntentId,
        'type': 'Payment',
        'currency': 'PKR',
        'amount': widget.totalAmount,
      });

      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance.collection('cart').doc(doc.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId placed successfully!')),
      );
      Navigator.popUntil(context, (route) => route.isCurrent);
    } catch (e) {
      throw Exception('Error placing order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stripe Payment", style: GoogleFonts.aclonica(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Amount: ${widget.totalAmount.toStringAsFixed(2)} PKR",
              style: GoogleFonts.aclonica(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                "Pay Now",
                style: GoogleFonts.aclonica(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
