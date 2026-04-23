import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';

class ClosetRepository {
  final SupabaseClient _supabase;

  ClosetRepository(this._supabase);

  // Read all clothes for the current user
  Future<List<ClothingItem>> getClothes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final response = await _supabase
        .from('clothes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((item) => ClothingItem.fromMap(item)).toList();
  }

  // Upload the photo and insert the database record
  Future<ClothingItem> addClothing({
    required File imageFile,
    required String title,
    required String category,
    String? color,
    String? pattern,
    String? style,
    String? season,
    String? aiDescription,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // 1. Upload logic
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('clothes').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final imageUrlResponse = _supabase.storage.from('clothes').getPublicUrl(fileName);

    // 2. Insert into Database
    final data = {
      'user_id': user.id,
      'title': title,
      'image_url': imageUrlResponse,
      'category': category,
      if (color != null) 'color': color,
      if (pattern != null) 'pattern': pattern,
      if (style != null) 'style': style,
      if (season != null) 'season': season,
      if (aiDescription != null) 'ai_description': aiDescription,
    };

    final response = await _supabase
        .from('clothes')
        .insert(data)
        .select()
        .single();

    return ClothingItem.fromMap(response);
  }

  // Delete an item from db and storage
  Future<void> deleteClothing(ClothingItem item) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Remove from DB
    await _supabase.from('clothes').delete().eq('id', item.id).eq('user_id', user.id);

    // Try to remove from storage by parsing the file path
    try {
      final uri = Uri.parse(item.imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('clothes');
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('clothes').remove([filePath]);
      }
    } catch (e) {
      // Ignorar fallback errors if image storage fails gracefully
    }
  }
}
