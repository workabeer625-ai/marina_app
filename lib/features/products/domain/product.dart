class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.variantId,
    this.image,
    this.description = '',
    this.compareAtPrice,
  });
  final String id, name, description;
  final String? variantId;
  final double price;
  final double? compareAtPrice;
  final String? image;
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'].toString(),
    variantId: json['variantId']?.toString(),
    name: (json['name'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
    image: json['image']?.toString(),
  );
}
