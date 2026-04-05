import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    return response;
  }

  Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? gender,
    String? birthday,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = {
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
    };

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }

  Future<String> uploadAvatar(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = fileName;

    await _supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final imageUrlResponse = _supabase.storage.from('avatars').getPublicUrl(filePath);
    
    // Guardar URL en el perfil
    await _supabase.from('profiles').update({'avatar_url': imageUrlResponse}).eq('id', user.id);

    return imageUrlResponse;
  }
}
