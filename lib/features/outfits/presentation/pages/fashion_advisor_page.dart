import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/cloud_ai_stylist_service.dart';
import '../../../../core/services/vton_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../closet/data/repositories/closet_repository.dart';
import '../../data/models/outfit_suggestion.dart';
import '../../data/repositories/saved_outfits_repository.dart';
import 'virtual_try_on_page.dart';

class FashionAdvisorPage extends StatefulWidget {
  const FashionAdvisorPage({super.key});

  @override
  State<FashionAdvisorPage> createState() => _FashionAdvisorPageState();
}

class _FashionAdvisorPageState extends State<FashionAdvisorPage> {
  final ImagePicker _picker = ImagePicker();
  final CloudAIStylistService _aiService = CloudAIStylistService();
  final VTONService _vtonService = VTONService();
  late final ClosetRepository _closetRepository;
  late final SavedOutfitsRepository _savedOutfitsRepository;

  File? _userImage;
  String? _uploadedImageUrl;
  bool _isAnalyzing = false;
  String _currentStep = '';
  List<OutfitSuggestion> _suggestions = [];
  int _tryingOnIndex = -1; // Which card is currently generating a try-on

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _closetRepository = ClosetRepository(client);
    _savedOutfitsRepository = SavedOutfitsRepository(client);
  }

  Future<void> _startAnalysis() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() {
      _userImage = File(image.path);
      _isAnalyzing = true;
      _suggestions = [];
      _currentStep = 'Uploading your photo...';
    });

    try {
      // Step 1: Upload photo to Supabase
      final fileName = 'vton_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('clothes')
          .upload(fileName, _userImage!);
      _uploadedImageUrl = Supabase.instance.client.storage
          .from('clothes')
          .getPublicUrl(fileName);

      // Step 2: Fetch closet
      setState(() => _currentStep = 'Scanning your wardrobe...');
      final myClothes = await _closetRepository.getClothes();
      if (myClothes.isEmpty) {
        throw 'Your closet is empty. Add some clothes first!';
      }

      final clothesContext = myClothes
          .map((e) => {
                'id': e.id,
                'name': e.title,
                'type': e.category,
                'color': e.color ?? 'N/A',
                'style': e.style ?? 'N/A',
                'pattern': e.pattern ?? 'N/A',
              })
          .toList();

      // Step 3: Gemini generates multiple outfits
      setState(() => _currentStep = 'AI is crafting your outfits...');
      final rawSuggestions = await _aiService.generateMultipleOutfits(
        availableClothes: clothesContext,
        contextImage: _userImage,
      );

      final suggestions = rawSuggestions
          .map((json) => OutfitSuggestion.fromJson(json, myClothes))
          .where((s) => s.items.isNotEmpty)
          .toList();

      setState(() {
        _suggestions = suggestions;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _currentStep = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _tryOnOutfit(int index) async {
    if (_uploadedImageUrl == null) return;
    final suggestion = _suggestions[index];

    setState(() => _tryingOnIndex = index);

    try {
      final resultImageUrl = await _vtonService.tryOn(
        humanImageUrl: _uploadedImageUrl!,
        garmentImageUrl: suggestion.primaryGarment.imageUrl,
      );

      setState(() {
        _suggestions[index].tryOnImageUrl = resultImageUrl;
        _tryingOnIndex = -1;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VirtualTryOnPage(
              imageUrl: resultImageUrl,
              outfitName: suggestion.name,
              outfitDescription: suggestion.description,
              styleTip: suggestion.styleTip,
              itemIds: suggestion.itemIds,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _tryingOnIndex = -1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Try-on failed: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _saveOutfit(OutfitSuggestion suggestion) async {
    try {
      await _savedOutfitsRepository.saveOutfit(
        name: suggestion.name,
        description: suggestion.description,
        styleTip: suggestion.styleTip,
        itemIds: suggestion.itemIds,
        tryOnImageUrl: suggestion.tryOnImageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${suggestion.name}" saved to your outfits!'),
            backgroundColor: AppTheme.accentPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Fashion Advisor'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isAnalyzing
          ? _buildLoadingState(isDark)
          : _suggestions.isEmpty
              ? _buildEmptyState(isDark)
              : _buildSuggestionsView(isDark),
    );
  }

  // ─── EMPTY STATE (before photo upload) ──────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple,
                    AppTheme.accentPurple.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Outfit Generator',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload a photo of yourself and our AI will suggest multiple outfit combinations from your closet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startAnalysis,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Upload My Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOADING STATE ──────────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppTheme.accentPurple,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _currentStep,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds...',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUGGESTIONS VIEW (outfit cards) ─────────────────────────────

  Widget _buildSuggestionsView(bool isDark) {
    return Column(
      children: [
        // Header with user photo & "try again"
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              if (_userImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _userImage!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your AI Suggestions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_suggestions.length} outfit ideas for you',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _startAnalysis,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Outfit cards list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) =>
                _buildOutfitCard(index, isDark),
          ),
        ),
      ],
    );
  }

  // ─── SINGLE OUTFIT CARD ─────────────────────────────────────────

  Widget _buildOutfitCard(int index, bool isDark) {
    final suggestion = _suggestions[index];
    final isTryingOn = _tryingOnIndex == index;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Garment thumbnails
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestion.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final item = suggestion.items[i];
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          item.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.checkroom,
                                color: AppTheme.accentPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkTextGrey
                                : AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Outfit name & description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              suggestion.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              suggestion.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppTheme.darkTextGrey : AppTheme.textGrey,
              ),
            ),
          ),

          // ── Style tip badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates,
                      size: 16, color: AppTheme.accentPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.styleTip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Try It On button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTryingOn ? null : () => _tryOnOutfit(index),
                    icon: isTryingOn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_search_rounded, size: 18),
                    label: Text(isTryingOn ? 'Generating...' : 'Try It On'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => _saveOutfit(suggestion),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    color: AppTheme.accentPurple,
                    tooltip: 'Save Outfit',
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
