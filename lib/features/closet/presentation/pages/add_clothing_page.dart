import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/closet_provider.dart';

class AddClothingPage extends ConsumerStatefulWidget {
  const AddClothingPage({super.key});

  @override
  ConsumerState<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends ConsumerState<AddClothingPage> {
  final _titleController = TextEditingController();
  final _colorController = TextEditingController();
  final _patternController = TextEditingController();
  final _styleController = TextEditingController();
  final _seasonController = TextEditingController();
  final _aiDescriptionController = TextEditingController();
  
  File? _selectedImage;
  String? _selectedCategory;
  bool _isAnalyzing = false;

  final List<String> _categories = [
    'Tops', 'Bottoms', 'Shoes', 'Outerwear', 'Accessories', 'Camiseta', 'Pantalón', 'Zapatos', 'Chaqueta', 'Vestido', 'Falda', 'Sudadera', 'Accesorio'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _colorController.dispose();
    _patternController.dispose();
    _styleController.dispose();
    _seasonController.dispose();
    _aiDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final initialFile = File(pickedFile.path);
      setState(() {
        _selectedImage = initialFile;
        _isAnalyzing = true;
      });

      try {
        // 1. Remove background
        final bgService = ref.read(backgroundRemovalProvider);
        final croppedFile = await bgService.removeBackground(initialFile);
        
        if (!mounted) return;
        final finalImage = croppedFile ?? initialFile;
        setState(() {
          _selectedImage = finalImage;
        });

        // 2. Extract Tags with Gemini
        final aiService = ref.read(visionAiProvider);
        final tags = await aiService.analyzeClothing(finalImage);
        
        if (!mounted) return;
        setState(() {
          // Attempt to match category gracefully
          final cat = tags['category'] ?? '';
          if (_categories.contains(cat)) {
            _selectedCategory = cat;
          } else if (cat.isNotEmpty && !_categories.contains(cat)) {
            // we could either add to list or force default
            _categories.add(cat);
            _selectedCategory = cat;
          }

          _colorController.text = tags['color'] ?? '';
          _patternController.text = tags['pattern'] ?? '';
          _styleController.text = tags['style'] ?? '';
          _seasonController.text = tags['season'] ?? '';
          _aiDescriptionController.text = tags['ai_description'] ?? '';
          
          // Auto-generate a title if empty based on tags
          if (_titleController.text.isEmpty && cat.isNotEmpty) {
             final color = tags['color'] ?? '';
             _titleController.text = '$color $cat'.trim();
          }
        });
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error analyzing image.')),
           );
        }
      } finally {
        if (mounted) {
           setState(() {
             _isAnalyzing = false;
           });
        }
      }
    }
  }

  void _saveClothing() async {
    final title = _titleController.text.trim();
    if (_selectedImage == null || _selectedCategory == null || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo, title and category.')),
      );
      return;
    }

    await ref.read(closetNotifierProvider.notifier).addClothing(
      image: _selectedImage!,
      title: title,
      category: _selectedCategory!,
      color: _colorController.text.isEmpty ? null : _colorController.text.trim(),
      pattern: _patternController.text.isEmpty ? null : _patternController.text.trim(),
      style: _styleController.text.isEmpty ? null : _styleController.text.trim(),
      season: _seasonController.text.isEmpty ? null : _seasonController.text.trim(),
      aiDescription: _aiDescriptionController.text.isEmpty ? null : _aiDescriptionController.text.trim(),
    );

    if (mounted && !ref.read(closetNotifierProvider).hasError) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final closetState = ref.watch(closetNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Digitize Item',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: () {
                  if (_isAnalyzing || closetState.isLoading) return;
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo'),
                            onTap: () {
                              context.pop();
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () {
                              context.pop();
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 2),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: AppTheme.accentPurple.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload item photo',
                              style: TextStyle(color: AppTheme.textGrey),
                            ),
                          ],
                        )
                      : (_isAnalyzing
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: AppTheme.accentPurple),
                                  SizedBox(height: 16),
                                  Text(
                                    'AI Analyzing & Removing background...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : null),
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              TextField(
                controller: _titleController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Item Title',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: _categories.toSet().toList().map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colorController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Color',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _patternController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Pattern',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _styleController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Style',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _seasonController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Season',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _aiDescriptionController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'AI Description',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),

              if (closetState.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  closetState.error.toString(),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: (closetState.isLoading || _isAnalyzing || _selectedImage == null) ? null : _saveClothing,
                child: closetState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Add to Closet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
