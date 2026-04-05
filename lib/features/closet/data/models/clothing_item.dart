class ClothingItem {
  final String id;
  final String userId;
  final String title;
  final String imageUrl;
  final String category;
  final String? color;
  final DateTime createdAt;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.imageUrl,
    required this.category,
    this.color,
    required this.createdAt,
  });

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      imageUrl: map['image_url'] as String,
      category: map['category'] as String,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'image_url': imageUrl,
      'category': category,
      if (color != null) 'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
