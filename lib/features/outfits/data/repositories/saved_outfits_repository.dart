import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for saving and retrieving user's favorite outfit combinations.
class SavedOutfitsRepository {
  final SupabaseClient _supabase;

  SavedOutfitsRepository(this._supabase);

  /// Save an outfit to the database.
  Future<void> saveOutfit({
    required String name,
    required String description,
    required String styleTip,
    required List<String> itemIds,
    String? tryOnImageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _supabase.from('saved_outfits').insert({
      'user_id': user.id,
      'name': name,
      'description': description,
      'style_tip': styleTip,
      'item_ids': itemIds,
      'try_on_image_url': tryOnImageUrl,
    });
  }

  /// Get all saved outfits for the current user.
  Future<List<Map<String, dynamic>>> getSavedOutfits() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final response = await _supabase
        .from('saved_outfits')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Delete a saved outfit by ID.
  Future<void> deleteOutfit(String outfitId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _supabase
        .from('saved_outfits')
        .delete()
        .eq('id', outfitId)
        .eq('user_id', user.id);
  }
}
