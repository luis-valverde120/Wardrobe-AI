import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentProfile();
});

class EditProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  ProfileRepository get _repository => ref.watch(profileRepositoryProvider);

  Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? gender,
    String? birthday,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(
        fullName: fullName,
        bio: bio,
        gender: gender,
        birthday: birthday,
      );
      state = const AsyncValue.data(null);
      // Forzamos al profileProvider a que dispare una nueva busqueda en Supabase
      ref.invalidate(profileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.uploadAvatar(imageFile);
      state = const AsyncValue.data(null);
      ref.invalidate(profileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final editProfileNotifierProvider =
    NotifierProvider<EditProfileNotifier, AsyncValue<void>>(
  () => EditProfileNotifier(),
);
