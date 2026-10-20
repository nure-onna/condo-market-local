class Product {
  final int id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> categorias;
  final bool emDestaque;

  Product({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.createdAt,
    this.categorias = const [],
    this.emDestaque = false,
  });

  factory Product.aPartirDeJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      categorias:
          (json['categories'] as List<dynamic>?)
              ?.map((categoria) => categoria.toString())
              .toList() ??
          const [],
      emDestaque: json['is_featured'] == true,
    );
  }

  Map<String, dynamic> converterParaJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'categories': categorias,
      'is_featured': emDestaque,
    };
  }
}
