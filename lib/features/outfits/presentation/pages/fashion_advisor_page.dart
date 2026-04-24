import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloud_ai_stylist_service.dart';
import '../../../../core/services/mock_closet_service.dart';
import 'dart:io';
import 'virtual_try_on_page.dart';

class FashionAdvisorPage extends StatefulWidget {
  const FashionAdvisorPage({Key? key}) : super(key: key);

  @override
  State<FashionAdvisorPage> createState() => _FashionAdvisorPageState();
}

class _FashionAdvisorPageState extends State<FashionAdvisorPage> {
  final ImagePicker _picker = ImagePicker();
  final CloudAIStylistService _aiService = CloudAIStylistService();
  final MockClosetService _closetService = MockClosetService();

  File? _contextImage;
  String? _detectedOccasion;
  String? _outfitDescription;
  String? _imagePrompt;
  bool _isAnalyzingVision = false;
  bool _isGeneratingOutfit = false;

  Future<void> _pickContextImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _contextImage = File(image.path);
        _detectedOccasion = null;
        _outfitDescription = null;
        _imagePrompt = null;
      });
      
      // Llamamos directo a generar, porque Gemini hará las 2 cosas: Visión y Decisión en 1 solo pase
      _generateOutfitRecommendation();
    }
  }

  Future<void> _generateOutfitRecommendation() async {
    setState(() {
      _isGeneratingOutfit = true;
    });

    try {
      final clothes = _closetService.getMockClothes();
      final result = await _aiService.generateOutfit(
        availableClothes: clothes,
        contextImage: _contextImage,
      );

      setState(() {
        _detectedOccasion = result['occasion'];
        _outfitDescription = result['description'];
        _imagePrompt = result['recommended_item_id']; // Pasamos el ID del item como "prompt" a la siguiente pantalla
        _isGeneratingOutfit = false;
      });
    } catch (e) {
      setState(() {
        _outfitDescription = "Hubo un error contactando a Gemini API: $e";
        _isGeneratingOutfit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor de Moda IA'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '1. Análisis de Contexto (Visión)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickContextImage,
              icon: const Icon(Icons.image),
              label: const Text('Subir Foto del Evento/Estilo'),
            ),
            if (_contextImage != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_contextImage!, height: 150, fit: BoxFit.cover),
              ),
            ],
            if (_detectedOccasion != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Contexto Detectado: $_detectedOccasion', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '2. Lógica de Vestuario (Gemma LLM)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_isGeneratingOutfit) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),
                const Center(child: Text('Aplicando reglas de curaduría de moda...')),
              ] else if (_outfitDescription != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _outfitDescription!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VirtualTryOnPage(prompt: _imagePrompt!),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Probar Outfit en Mí', style: TextStyle(fontSize: 16)),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }
}
