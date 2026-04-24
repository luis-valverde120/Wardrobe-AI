import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../closet/data/models/clothing_item.dart';
import '../../../closet/data/repositories/closet_repository.dart';
import '../../data/repositories/saved_outfits_repository.dart';

class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  late final SavedOutfitsRepository _outfitRepo;
  late final ClosetRepository _closetRepo;
  List<Map<String, dynamic>> _savedOutfits = [];
  List<ClothingItem> _allClothes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _outfitRepo = SavedOutfitsRepository(client);
    _closetRepo = ClosetRepository(client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _outfitRepo.getSavedOutfits(),
        _closetRepo.getClothes(),
      ]);
      setState(() {
        _savedOutfits = results[0] as List<Map<String, dynamic>>;
        _allClothes = results[1] as List<ClothingItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading outfits: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _deleteOutfit(String id) async {
    try {
      await _outfitRepo.deleteOutfit(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outfit deleted'),
            backgroundColor: AppTheme.accentPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<ClothingItem> _getItemsForOutfit(Map<String, dynamic> outfit) {
    final itemIds =
        (outfit['item_ids'] as List<dynamic>?)?.map((e) => e.toString()) ?? [];
    return itemIds
        .map((id) => _allClothes.where((c) => c.id.toString() == id))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Outfits'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPurple))
          : _savedOutfits.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.accentPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedOutfits.length,
                    itemBuilder: (context, index) =>
                        _buildOutfitCard(_savedOutfits[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 72,
            color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Saved Outfits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the AI Fashion Advisor to create\nand save outfit ideas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit, bool isDark) {
    final items = _getItemsForOutfit(outfit);
    final tryOnUrl = outfit['try_on_image_url'] as String?;
    final name = outfit['name'] as String? ?? 'Outfit';
    final description = outfit['description'] as String? ?? '';
    final styleTip = outfit['style_tip'] as String? ?? '';
    final outfitId = outfit['id'] as String;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Try-on image if saved
          if (tryOnUrl != null && tryOnUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                tryOnUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // Garment thumbnails
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      items[i].imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.accentPurple.withValues(alpha: 0.1),
                        child: const Icon(Icons.checkroom,
                            size: 20, color: AppTheme.accentPurple),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Description
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
                  height: 1.4,
                ),
              ),
            ),

          // Style tip
          if (styleTip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates,
                      size: 14, color: AppTheme.accentPurple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      styleTip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Delete button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showDeleteConfirmation(outfitId, name),
                icon: Icon(Icons.delete_outline,
                    size: 16, color: Colors.red.shade300),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: Text('Remove "$name" from your saved outfits?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOutfit(id);
            },
            child:
                Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
