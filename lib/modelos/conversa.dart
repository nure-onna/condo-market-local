class ChatSession {
  final int id;
  final int productId;
  final String sellerId;
  final String buyerId;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.createdAt,
  });

  factory ChatSession.aPartirDeJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      sellerId: json['seller_id'] as String,
      buyerId: json['buyer_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> converterParaJson() {
    return {
      'product_id': productId,
      'seller_id': sellerId,
      'buyer_id': buyerId,
    };
  }
}
