import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class Paymentwalletscreen extends StatefulWidget {
  const Paymentwalletscreen({super.key});

  @override
  State<Paymentwalletscreen> createState() => _PaymentwalletscreenState();
}

class _PaymentwalletscreenState extends State<Paymentwalletscreen> with SingleTickerProviderStateMixin {
  String _userName = "Guest";
  String _email = "guest@example.com";
  String _imageUrl = "https://res.cloudinary.com/dpfebhnli/image/upload/v1742469623/gazatube_nxu2k8.jpg";
  bool _isProfileLoading = false;
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> walletTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchProfileData();
    fetchPayments();
    fetchWalletTransactions();
  }

  Future<void> fetchProfileData() async {
    setState(() => _isProfileLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _userName = "Guest";
          _email = "guest@example.com";
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

  Future<void> fetchPayments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to view payments';
        });
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();
      setState(() {
        payments = snapshot.docs.map((doc) => {
          'orderId': doc.data()['orderId'] ?? 'N/A',
          'totalWithDelivery': doc.data()['totalWithDelivery']?.toDouble() ?? 0.0,
          'walletName': doc.data()['walletName'] ?? 'N/A',
          'paymentIntentId': doc.data()['paymentIntentId'] ?? 'N/A',
          'orderDate': (doc.data()['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        }).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load payments: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching payments: $e')),
        );
      }
    }
  }

  Future<void> fetchWalletTransactions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to view wallet transactions';
        });
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('wallet_transactions')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        walletTransactions = snapshot.docs.map((doc) => {
          'transactionId': doc.id,
          'type': doc.data()['type'] ?? 'unknown',
          'amount': doc.data()['amount']?.toDouble() ?? 0.0,
          'currency': doc.data()['currency'] ?? 'USD',
          'status': doc.data()['status'] ?? 'unknown',
          'timestamp': (doc.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        }).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load wallet transactions: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching wallet transactions: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(35), bottomLeft: Radius.circular(35)),
                gradient: RadialGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent, Colors.indigo],
                  center: Alignment.center,
                  radius: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isProfileLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blueAccent.withOpacity(0.8), Colors.purpleAccent.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                          backgroundColor: Colors.white,
                          child: _imageUrl.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 6),
                  Text(
                    _email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 16),
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: const [
                Tab(text: "Payment"),
                Tab(text: "Wallet"),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _buildTransactionCard(
                        context,
                        title: 'Order #${payment['orderId']}',
                        subtitle: 'Wallet: ${payment['walletName']}',
                        amount: payment['totalWithDelivery'],
                        currency: 'PKR',
                        status: 'Completed',
                        timestamp: payment['orderDate'],
                        delay: (index * 100).ms,
                      );
                    },
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: walletTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = walletTransactions[index];
                      return _buildTransactionCard(
                        context,
                        title: '${transaction['type'].capitalize()} #${transaction['transactionId'].substring(0, 8)}',
                        subtitle: transaction['type'].capitalize(),
                        amount: transaction['amount'],
                        currency: transaction['currency'],
                        status: transaction['status'],
                        timestamp: transaction['timestamp'],
                        delay: (index * 100).ms,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required double amount,
        required String currency,
        required String status,
        required DateTime timestamp,
        required Duration delay,
      }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: $currency ${amount.toStringAsFixed(2)}', style: GoogleFonts.poppins()),
                Text('Status: $status', style: GoogleFonts.poppins()),
                Text('Date: ${DateFormat.yMMMd().add_jm().format(timestamp)}', style: GoogleFonts.poppins()),
                Text(subtitle, style: GoogleFonts.poppins()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.poppins(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            DateFormat.yMMMd().format(timestamp),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          trailing: Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, delay: delay, curve: Curves.easeInOut),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}