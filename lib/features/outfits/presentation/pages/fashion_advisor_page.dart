import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/cloud_ai_stylist_service.dart';
import '../../../closet/data/repositories/closet_repository.dart';
import '../../../../core/services/vton_service.dart';
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

  File? _userImage;
  bool _isProcessing = false;
  String _currentStep = '';

  @override
  void initState() {
    super.initState();
    _closetRepository = ClosetRepository(Supabase.instance.client);
  }

  Future<void> _startMagicTryOn() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() {
      _userImage = File(image.path);
      _isProcessing = true;
      _currentStep = 'Starting process...';
    });

    try {
      // STEP 1: Upload your photo to Supabase so Fal.ai can access it
      print("DEBUG: Uploading image to Supabase...");
      setState(() => _currentStep = 'Uploading your photo to the cloud...');
      final fileName = 'vton_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('clothes')
          .upload(fileName, _userImage!);
      final humanUrl = Supabase.instance.client.storage
          .from('clothes')
          .getPublicUrl(fileName);
      print("DEBUG: Human URL ready: $humanUrl");

      // STEP 2: Get your real clothes
      print("DEBUG: Querying closet from Supabase...");
      setState(
        () => _currentStep = 'Finding the perfect garment in your closet...',
      );
      final myClothes = await _closetRepository.getClothes();
      if (myClothes.isEmpty) throw 'Your closet is empty in the database.';

      final clothesContext = myClothes
          .map(
            (e) => {
              'id': e.id,
              'name': e.title,
              'type': e.category,
              'color': e.color ?? 'N/A',
            },
          )
          .toList();

      // STEP 3: Gemini picks the garment (Surprise Mode)
      print("DEBUG: Gemini choosing garment...");
      setState(
        () => _currentStep = 'AI is choosing the best outfit for you...',
      );
      final aiDecision = await _aiService.generateOutfit(
        availableClothes: clothesContext,
        contextImage: _userImage,
      );

      final recommendedId = aiDecision['recommended_item_id'];
      final chosenGarment = myClothes.firstWhere(
        (c) => c.id.toString() == recommendedId.toString(),
        orElse: () => myClothes.first,
      );
      print(
        "DEBUG: Chosen garment: ${chosenGarment.title} - URL: ${chosenGarment.imageUrl}",
      );

      // STEP 4: FAL.AI generates the real image of you wearing the clothes
      print("DEBUG: Calling Fal.ai (IDM-VTON)...");
      setState(
        () => _currentStep = 'Generating your image with the outfit on...',
      );
      final resultImageUrl = await _vtonService.tryOn(
        humanImageUrl: humanUrl,
        garmentImageUrl: chosenGarment.imageUrl,
      );
      print("DEBUG: Success! Final Fal.ai URL: $resultImageUrl");

      setState(() => _isProcessing = false);

      // STEP 5: Show the result
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VirtualTryOnPage(imageUrl: resultImageUrl),
          ),
        );
      }
    } catch (e) {
      print("DEBUG ERROR: $e");
      setState(() {
        _isProcessing = false;
        _currentStep = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'AI Virtual Try-On',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
            const SizedBox(height: 24),
            const Text(
              'Surprise Mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload a photo of yourself and let AI pick your outfit and try it on instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),

            if (_isProcessing) ...[
              const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              ),
              const SizedBox(height: 20),
              Text(
                _currentStep,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _startMagicTryOn,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick my photo & Dress me up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
