import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  File? _image1;
  File? _image2;
  String? _imageUrl1;
  String? _imageUrl2;
  String? _selectedCategory;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Cloudinary configuration
  final String _cloudinaryUploadUrl =
      "https://api.cloudinary.com/v1_1/dpfebhnli/image/upload";
  final String _cloudinaryPreset = "ml_default";
  final String _defaultImageUrl =
      "https://res.cloudinary.com/dpfebhnli/image/upload/v1742469623/gazatube_nxu2k8.jpg";

  // List of categories
  final List<String> _categories = [
    'Sports Shoes',
    'Casual Shoes',
    'Boots',
    'Formal Shoes',
    'Sandals & Slippers',
    'Sneakers',
  ];

  // Pick image from gallery
  Future<void> pickImage(int imageNumber) async {
    try {
      final XFile? pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        if (await imageFile.exists()) {
          setState(() {
            if (imageNumber == 1) {
              _image1 = imageFile;
            } else {
              _image2 = imageFile;
            }
          });
          print('Image $imageNumber picked successfully: ${pickedFile.path}');
        } else {
          _showErrorDialog('Selected image file is invalid');
        }
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
      print('Error picking image $imageNumber: $e');
    }
  }

  // Upload image to Cloudinary
  Future<String?> uploadImageToCloudinary(File image, String imageLabel) async {
    try {
      if (!await image.exists()) {
        throw Exception('$imageLabel file does not exist');
      }

      final uri = Uri.parse(_cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _cloudinaryPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonData['secure_url'] != null) {
        print('$imageLabel uploaded successfully: ${jsonData['secure_url']}');
        return jsonData['secure_url'];
      } else {
        print(
            'Cloudinary error for $imageLabel: ${jsonData['error']?['message'] ?? 'Unknown error'}');
        throw Exception(
            'Failed to upload $imageLabel: ${jsonData['error']?['message'] ?? 'Status code ${response.statusCode}'}');
      }
    } catch (e) {
      print('Error uploading $imageLabel: $e');
      _showErrorDialog('Error uploading $imageLabel: $e');
      return null;
    }
  }

  // Upload product to Firestore with initial rating
  Future<void> uploadProduct() async {
    String name = nameController.text.trim();
    String priceText = priceController.text.trim();
    double? price = double.tryParse(priceText);
    double discountPercentage = double.tryParse(discountController.text.trim()) ?? 0.0;

    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (name.isEmpty ||
        price == null ||
        _image1 == null ||
        _image2 == null ||
        _selectedCategory == null ||
        userId == null) {
      _showErrorDialog(
          'Please enter valid name, price, select a category, select both images, and ensure you are logged in');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload images
      print('Starting upload for first image...');
      _imageUrl1 =
          await uploadImageToCloudinary(_image1!, 'First image') ?? _defaultImageUrl;

      print('Starting upload for second image...');
      _imageUrl2 =
          await uploadImageToCloudinary(_image2!, 'Second image') ?? _defaultImageUrl;

      // Store in Firestore
      final docRef = await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'image1': _imageUrl1,
        'image2': _imageUrl2,
        'userId': userId,
        'rating': 0.0,
        'discountPercentage': discountPercentage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product uploaded successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update rating
      await updateProductRating(docRef.id, name);

      // Navigate to Home
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Home()));
    } catch (e) {
      _showErrorDialog('Error: $e');
      print('Error during product upload: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  // Function to update rating in products collection from Orders
  Future<void> updateProductRating(String productId, String productName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('productName', isEqualTo: productName)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No orders found for $productName');
        return;
      }

      double totalRating = 0;
      int count = 0;
      for (var doc in snapshot.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble();
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }

      double newRating = count > 0 ? totalRating / count : 0.0;

      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'rating': newRating,
      });

      print('Updated rating for $productName to $newRating');
    } catch (e) {
      print('Error updating rating for $productName: $e');
      _showErrorDialog('Error updating rating: $e');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name Input
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.label),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price Input
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Discount Percentage Input
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Discount Percentage (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.discount),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Category Dropdown
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.category),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            hint: const Text('Select a category'),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Image Selection
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return isLargeScreen
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildImagePicker(1, constraints.maxWidth / 2 - 16),
                              _buildImagePicker(2, constraints.maxWidth / 2 - 16),
                            ],
                          )
                              : Column(
                            children: [
                              _buildImagePicker(1, constraints.maxWidth),
                              const SizedBox(height: 16),
                              _buildImagePicker(2, constraints.maxWidth),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Upload Button
                      Center(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : uploadProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 40 : 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Upload to Firestore',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading Overlay
            if (isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget to build image picker with preview
  Widget _buildImagePicker(int imageNumber, double width) {
    final image = imageNumber == 1 ? _image1 : _image2;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: width < 600 ? 150 : 200,
              width: width < 600 ? 150 : 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: image != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  height: 150,
                  width: 150,
                ),
              )
                  : Center(
                child: Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => pickImage(imageNumber),
              icon: const Icon(Icons.photo_camera),
              label: Text('Pick Image $imageNumber'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}