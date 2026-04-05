import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentProfile();
});

class EditProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  EditProfileNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile({required String fullName, String? bio}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(fullName: fullName, bio: bio);
      state = const AsyncValue.data(null);
      // Forzamos al profileProvider a que dispare una nueva búsqueda en Supabase
      _ref.invalidate(profileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.uploadAvatar(imageFile);
      state = const AsyncValue.data(null);
      _ref.invalidate(profileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final editProfileNotifierProvider = StateNotifierProvider<EditProfileNotifier, AsyncValue<void>>((ref) {
  return EditProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});
