import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/saved_outfits_repository.dart';

class VirtualTryOnPage extends StatelessWidget {
  final String imageUrl;
  final String? outfitName;
  final String? outfitDescription;
  final String? styleTip;
  final List<String>? itemIds;

  const VirtualTryOnPage({
    super.key,
    required this.imageUrl,
    this.outfitName,
    this.outfitDescription,
    this.styleTip,
    this.itemIds,
  });

  Future<void> _saveOutfit(BuildContext context) async {
    try {
      final repo = SavedOutfitsRepository(Supabase.instance.client);
      await repo.saveOutfit(
        name: outfitName ?? 'My Outfit',
        description: outfitDescription ?? '',
        styleTip: styleTip ?? '',
        itemIds: itemIds ?? [],
        tryOnImageUrl: imageUrl,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outfit saved!'),
            backgroundColor: AppTheme.accentPurple,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text(outfitName ?? 'Your Result'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Try-on image
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.accentPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your look...',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextGrey
                                  : AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              size: 48,
                              color: isDark
                                  ? AppTheme.darkTextGrey
                                  : AppTheme.textGrey),
                          const SizedBox(height: 12),
                          const Text('Failed to load the generated image.'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Style tip
          if (styleTip != null && styleTip!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates,
                        size: 16, color: AppTheme.accentPurple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        styleTip!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                // Back button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveOutfit(context),
                    icon:
                        const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: const Text('Save Outfit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
