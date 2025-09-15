import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final bool isPrivacyEnabled;

  const ProfileScreen({super.key, required this.isPrivacyEnabled});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "John Doe";
  String _email = "john.doe@example.com";
  String _phoneNumber = "+1234567890";
  String _imageUrl = "https://res.cloudinary.com/dpfebhnli/image/upload/v1742469623/gazatube_nxu2k8.jpg";
  final String _cloudinaryUploadUrl = "https://api.cloudinary.com/v1_1/dpfebhnli/upload";
  final String _cloudinaryPreset = "ml_default";
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view your profile')),
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('profile')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['userName'] ?? _userName;
          _email = doc.data()?['email'] ?? _email;
          _phoneNumber = doc.data()?['phoneNumber'] ?? _phoneNumber;
          _imageUrl = doc.data()?['imageUrl'] ?? _imageUrl;
        });
      }
    } catch (e) {
      String errorMessage = 'Error fetching profile';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errorMessage = 'Permission denied. Please check your access rights.';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Network error. Please check your connection.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final file = File(image.path);
        if (file.lengthSync() > 5 * 1024 * 1024) { // Limit to 5MB
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size exceeds 5MB limit')),
          );
          setState(() => _isUploading = false);
          return;
        }
        final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl))
          ..fields['upload_preset'] = _cloudinaryPreset
          ..files.add(await http.MultipartFile.fromPath('file', image.path));
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await http.Response.fromStream(response);
          final jsonData = jsonDecode(responseData.body);
          final newImageUrl = jsonData['secure_url'] as String;
          setState(() => _imageUrl = newImageUrl);
          await _updateProfileInFirestore(newImageUrl);
          await _fetchProfileData(); // Refresh data from Firestore
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
    setState(() => _isUploading = false);
  }

  Future<void> _updateProfileInFirestore(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        await FirebaseFirestore.instance.collection('profile').doc(userId).set({
          'userId': userId,
          'userName': _userName,
          'email': _email,
          'phoneNumber': _phoneNumber,
          'imageUrl': imageUrl,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      String errorMessage = 'Error updating profile';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errorMessage = 'Permission denied. Please check your access rights.';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Network error. Please check your connection.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: _userName);
    TextEditingController emailController = TextEditingController(text: _email);
    TextEditingController phoneController = TextEditingController(text: _phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: !widget.isPrivacyEnabled, // Disable email editing if privacy is enabled
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: widget.isPrivacyEnabled ? '*****@*****.com' : null,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  (!widget.isPrivacyEnabled && emailController.text.trim().isEmpty) ||
                  (!widget.isPrivacyEnabled && !emailController.text.contains('@'))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid name and email')),
                );
                return;
              }
              setState(() {
                _userName = nameController.text.trim();
                if (!widget.isPrivacyEnabled) {
                  _email = emailController.text.trim();
                }
                _phoneNumber = phoneController.text.trim();
              });
              await _updateProfileInFirestore(_imageUrl);
              await _fetchProfileData(); // Refresh data from Firestore
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms),
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_imageUrl),
                      backgroundColor: Colors.white,
                    ).animate().scale(duration: 500.ms),
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.isPrivacyEnabled ? '*****@*****.com' : _email,
                                style: GoogleFonts.poppins(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              _phoneNumber,
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),
                        if (widget.isPrivacyEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Private Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit),
                  label: Text(
                    "Edit Profile",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}