class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final double rating;
  final int ratingCount;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
    required this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] is num) ? json['price'].toDouble() : 0.0,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      rating: (json['rating'] != null && json['rating']['rate'] is num)
          ? (json['rating']['rate'] as num).toDouble()
          : 0.0,
      ratingCount: (json['rating'] != null && json['rating']['count'] is int)
          ? json['rating']['count']
          : 0,
    );
  }
}
