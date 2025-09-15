import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

class GoogleAuthh extends StatefulWidget {
  const GoogleAuthh({super.key});

  @override
  State<GoogleAuthh> createState() => _GoogleAuthhState();
}

class _GoogleAuthhState extends State<GoogleAuthh> {
  @override
  void initState() {
    super.initState();
    _googleSignIn.initialize();
  }

  final List<String> userAuthenticateHint = ['email', 'profile'];

  Future<void> _signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: userAuthenticateHint,
      );

      final auth = await account.authorizationClient.authorizationForScopes(
        userAuthenticateHint,
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: auth?.accessToken,
        idToken: account.authentication.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _signInWithGoogle();
          },
          child: Text('Sign-in with Google'),
        ),
      ),
    );
  }
}
