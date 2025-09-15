import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id; // Firestore document ID
  final String productId; // Explicitly stored productId (matches id)
  final String name;
  final String imagePath; // Maps to image1
  final String? secondaryImagePath; // Maps to image2
  final double? price;
  final String? category;
  final String? userId;
  final double? rating;
  final double? discountPercentage;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.imagePath,
    this.secondaryImagePath,
    this.price,
    this.category,
    this.userId,
    this.rating,
    this.discountPercentage,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      productId: data['productId'] ?? doc.id,
      name: data['name'] ?? '',
      imagePath: data['image1'] ?? data['imagePath'] ?? '',
      secondaryImagePath: data['image2'] ?? data['secondaryImagePath'],
      price: (data['price'] as num?)?.toDouble(),
      category: data['category'],
      userId: data['userId'],
      rating: (data['rating'] as num?)?.toDouble(),
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image1': imagePath,
      'image2': secondaryImagePath,
      'price': price,
      'category': category,
      'userId': userId,
      'rating': rating,
      'discountPercentage': discountPercentage,
    };
  }
}