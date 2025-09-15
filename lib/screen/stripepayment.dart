import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final String _publishableKey = 'pk_test_51PmTq6DBEjCGrVlztyETefPl1kILA95pWqe7QEkVVhUpqLdHs1LzVupKmOBG3YqJyFR8GIW3HrS0T7e4v4Vh3EGp00TssCNn5G'; // Replace with your Stripe publishable key

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = _publishableKey;
    // Ensure Stripe is initialized
    Stripe.instance.applySettings().catchError((error) {
      print("Stripe initialization error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stripe initialization failed: $error")),
      );
    });
  }

  // Generate a unique order ID
  String _generateOrderId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000; // Generates 6-digit number
    return '#$number';
  }

  // Process the payment and save order
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Create PaymentIntent
      paymentIntent = await createPaymentIntent(
        widget.totalAmount.toStringAsFixed(0), // Convert to integer (PKR)
        "PKR",
      );

      // Initialize PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!["client_secret"],
          applePay: null, // Disabled Apple Pay
          googlePay: null, // Disabled Google Pay
          style: ThemeMode.dark,
          merchantDisplayName: 'Your Merchant Name', // Replace with your merchant name
        ),
      );

      // Present PaymentSheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful, save order
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
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Create PaymentIntent on backend
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      final body = {
        "amount": calculateAmount(amount),
        "currency": currency,
        "payment_method_types[]": "card",
      };
      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: body,
        headers: {
          "Authorization": "Bearer sk_test_51PmTq6DBEjCGrVlzp8CZ4fCPlXvUCh88kkHg05Q53H2HTsseAqxTPoKFCpCN49rrbyHaEEE0IGDkngEBrhnvKrNQ00Nw1stgYn",
          "Content-Type": "application/x-www-form-urlencoded",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create PaymentIntent: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating PaymentIntent: $e");
    }
  }

  // Convert amount to paisa
  String calculateAmount(String amount) {
    final price = int.parse(amount) * 100;
    return price.toString();
  }

  // Save order to Firestore
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
        'transactionId': paymentIntentId, // Using paymentIntentId as transactionId
        'type': 'Payment', // Fixed type for payment transaction
        'currency': 'PKR', // Currency used in the payment
        'amount': widget.totalAmount, // Total amount of the transaction
      });

      // Clear the cart
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
            Text(
              "Click 'Pay Now' to enter card details",
              style: GoogleFonts.alegreya(fontSize: 16, color: Colors.grey.shade600),
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