import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/closet_repository.dart';
import '../../data/services/background_removal_service.dart';
import '../../data/services/vision_ai_service.dart';

final closetRepositoryProvider = Provider<ClosetRepository>((ref) {
  return ClosetRepository(Supabase.instance.client);
});

final backgroundRemovalProvider = Provider<BackgroundRemovalService>((ref) {
  return BackgroundRemovalService();
});

final visionAiProvider = Provider<VisionAiService>((ref) {
  return VisionAiService();
});

class ClosetNotifier extends AsyncNotifier<List<ClothingItem>> {
  @override
  Future<List<ClothingItem>> build() async {
    final repository = ref.watch(closetRepositoryProvider);
    return repository.getClothes();
  }

  Future<void> addClothing({
    required File image,
    required String title,
    required String category,
    String? color,
    String? pattern,
    String? style,
    String? season,
    String? aiDescription,
  }) async {
    final repository = ref.watch(closetRepositoryProvider);
    
    // Set to loading to show UI progress
    state = const AsyncValue.loading();
    
    try {
      final newItem = await repository.addClothing(
        imageFile: image,
        title: title,
        category: category,
        color: color,
        pattern: pattern,
        style: style,
        season: season,
        aiDescription: aiDescription,
      );
      
      // Update state cautiously by keeping previous items plus the new one
      final currentList = state.value ?? [];
      state = AsyncValue.data([newItem, ...currentList]);
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteClothing(ClothingItem item) async {
    final repository = ref.watch(closetRepositoryProvider);
    final previousState = state.value;
    
    // Set to loading
    state = const AsyncValue.loading();
    try {
      await repository.deleteClothing(item);
      
      if (previousState != null) {
        state = AsyncValue.data(
          previousState.where((element) => element.id != item.id).toList(),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final closetNotifierProvider = AsyncNotifierProvider<ClosetNotifier, List<ClothingItem>>(() {
  return ClosetNotifier();
});
