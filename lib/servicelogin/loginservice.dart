import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerceapp/screen/Home.dart';
import 'package:ecommerceapp/screen/Login.dart';

import '../screen/logiin.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is logged in and return the appropriate screen
  Widget getInitialScreen() {
    return _auth.currentUser != null ? const Home() :  Login();
  }

  // Stream to listen for authentication state changes
  Stream<Widget> get authStateChanges {
    return _auth.authStateChanges().map((User? user) {
      return user != null ? const Home() : const Login();
    });
  }
}