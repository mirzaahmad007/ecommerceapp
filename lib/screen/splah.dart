import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerceapp/screen/Home.dart';
import 'package:ecommerceapp/screen/Login.dart';

import 'logiin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _shiController;
  late AnimationController _waterController1;
  late AnimationController _waterController2;
  late Animation<double> _shiAnimation;
  late Animation<double> _waterAnimation1;
  late Animation<double> _waterAnimation2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _initializeAnimations();

    // Navigate to Home or Login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => user != null ? const Home() : const Login(),
        ),
      );
    });
  }

  void _initializeAnimations() {
    // Shi image animation
    _shiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shiAnimation = Tween<double>(
      begin: 0.0, // Adjusted by LayoutBuilder
      end: -20.0,
    ).animate(CurvedAnimation(parent: _shiController, curve: Curves.easeInOut));

    // Water flow animations
    _waterController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _waterController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _waterAnimation1 = Tween<double>(begin: 150, end: 180).animate(
      CurvedAnimation(parent: _waterController1, curve: Curves.easeInOut),
    );
    _waterAnimation2 = Tween<double>(begin: 200, end: 230).animate(
      CurvedAnimation(parent: _waterController2, curve: Curves.easeInOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    _shiController.reset();
    _shiController.forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      _waterController1.forward();
      _waterController2.forward(from: 0.5);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Restart shi animation when app resumes
      _startAnimations();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _shiController.dispose();
    _waterController1.dispose();
    _waterController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust shiAnimation begin value based on screen height
        _shiAnimation = Tween<double>(
          begin: -constraints.maxHeight,
          end: -20.0,
        ).animate(CurvedAnimation(parent: _shiController, curve: Curves.easeInOut));

        // Restart shi animation on every build
        _shiController.reset();
        _shiController.forward();

        return Scaffold(
          body: Stack(
            children: [
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xffFFD0B6),
                ),
              ),
              Positioned(
                top: -130,
                right: 60,
                child: Image(
                  image: const AssetImage("assets/images/whole.png"),
                  height: 400,
                  width: 400,
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedBuilder(
                animation: _shiController,
                builder: (context, child) {
                  return Positioned(
                    left: 10,
                    top: _shiAnimation.value,
                    child: Image(
                      image: const AssetImage("assets/images/shi.png"),
                      height: 250,
                      width: 250,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              Positioned(
                top: 350,
                left: 35,
                child: Text(
                  "Start Journey \n With Nike",
                  style: GoogleFonts.anton(fontSize: 48),
                ),
              ),
              Positioned(
                top: 500,
                left: 35,
                child: Text(
                  "Smart, gorgeous & fashionable \n collection",
                  style: GoogleFonts.openSans(fontSize: 18),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final user = FirebaseAuth.instance.currentUser;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => user != null ? const Home() : const Login(),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Positioned(
                      top: 660,
                      left: 80,
                      child: AnimatedBuilder(
                        animation: _waterController1,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 2000),
                            height: 150,
                            width: _waterAnimation1.value,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(100)),
                              color: Colors.red.withOpacity(0.4),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 640,
                      left: 55,
                      child: AnimatedBuilder(
                        animation: _waterController2,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 2000),
                            height: 200,
                            width: _waterAnimation2.value,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(100)),
                              color: Colors.red.withOpacity(0.4),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 690,
                      left: 68,
                      child: Image(
                        image: const AssetImage("assets/images/black.png"),
                        height: 150,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 715,
                      left: 145,
                      child: Text(
                        "Start",
                        style: GoogleFonts.sanchez(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}