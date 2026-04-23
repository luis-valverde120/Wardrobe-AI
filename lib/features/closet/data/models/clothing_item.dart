class ClothingItem {
  final String id;
  final String userId;
  final String title;
  final String imageUrl;
  final String category;
  final String? color;
  final String? pattern;
  final String? style;
  final String? season;
  final String? aiDescription;
  final DateTime createdAt;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.imageUrl,
    required this.category,
    this.color,
    this.pattern,
    this.style,
    this.season,
    this.aiDescription,
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
      pattern: map['pattern'] as String?,
      style: map['style'] as String?,
      season: map['season'] as String?,
      aiDescription: map['ai_description'] as String?,
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
      if (pattern != null) 'pattern': pattern,
      if (style != null) 'style': style,
      if (season != null) 'season': season,
      if (aiDescription != null) 'ai_description': aiDescription,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
