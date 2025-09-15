import 'package:ecommerceapp/screen/stripepayment.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'stripe_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double itemsTotal;
  const PaymentScreen({
    super.key,
    required this.itemsTotal,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Generate a unique order ID
  String _generateOrderId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000; // Generates 6-digit number
    return '#$number';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.12,
                      height: MediaQuery.of(context).size.height * 0.05,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Text(
                    "Payment Screen",
                    style: GoogleFonts.aclonica(
                      fontSize: 18,
                      color: theme.textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? theme.cardColor : null,
                gradient: theme.brightness == Brightness.dark
                    ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
                items: [
                  'https://cdn.dribbble.com/userupload/34163717/file/original-c84605801816b112c3e5e77b55d06abb.jpg?resize=400x0',
                  'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEiFVgFX-SdJMinPeIOnQN7wzF6J5UzHOgapuHBlSlEcSqatRuG8EDXaBL0BCVFyGP54hH_S5bJDuWf7EVI5BX_pf23DkJU1lbR0_6XEPy6zBz43PrB_GAZcV-fg29iM9r0a-53RLMH2VJQpSA6g-ci_jVqe7iaIKrRxRX3pT6bwxWv62klZ6KNWBXxs2x8/s1280/Ecommerce%20Website%20Banner%20Thumbnail.webp',
                  'https://img.freepik.com/free-psd/sneakers-template-design_23-2151796595.jpg?semt=ais_hybrid&w=740&q=80',
                ].map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Image.network(url, fit: BoxFit.cover),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        filled: true,
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        filled: true,
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        filled: true,
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: GoogleFonts.alegreya(color: theme.textTheme.bodyMedium?.color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        filled: true,
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total: ${widget.itemsTotal.toStringAsFixed(2)} PKR",
                    style: GoogleFonts.aclonica(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StripePaymentScreen(
                          totalAmount: widget.itemsTotal,
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          address: _addressController.text,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Pay with Stripe",
                  style: GoogleFonts.aclonica(fontSize: 18, color: theme.colorScheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}