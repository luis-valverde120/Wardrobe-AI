import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/services/vton_service.dart';

class VirtualTryOnPage extends StatefulWidget {
  final String prompt;

  const VirtualTryOnPage({Key? key, required this.prompt}) : super(key: key);

  @override
  State<VirtualTryOnPage> createState() => _VirtualTryOnPageState();
}

class _VirtualTryOnPageState extends State<VirtualTryOnPage> {
  final ImagePicker _picker = ImagePicker();
  final VTONService _vtonService = VTONService();
  
  File? _userSelfie;
  bool _isGenerating = false;
  bool _generationComplete = false;
  String? _finalImageUrl;
  String? _errorMessage;

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      setState(() {
        _userSelfie = File(image.path);
        _isGenerating = true;
        _errorMessage = null;
      });

      try {
        // En Fal.ai, algunos endpoints (como IDM-VTON) soportan Data URIs.
        final bytes = await _userSelfie!.readAsBytes();
        final base64String = base64Encode(bytes);
        final base64Image = "data:image/jpeg;base64,$base64String"; 

        // El prompt que recibimos es el ID del item recomendado (ej. '1')
        // Aquí deberías buscar la URL de tu repositorio real/Supabase correspondiente a ese ID.
        // Para la demo asumimos una URL de ropa de prueba en internet:
        final garmentUrl = "https://raw.githubusercontent.com/yisol/IDM-VTON/main/garment/00021_00.jpg"; 

        final resultUrl = await _vtonService.tryOn(
          humanImageUrl: base64Image,
          garmentImageUrl: garmentUrl,
        );

        setState(() {
          _finalImageUrl = resultUrl;
          _isGenerating = false;
          _generationComplete = true;
        });
      } catch (e) {
        setState(() {
          _isGenerating = false;
          _errorMessage = "Error en Try-On: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Try-On (Real)'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '3. Probador Virtual (IDM-VTON)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: Text(
                'Gemini recomendó el ID de prenda: \${widget.prompt}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            if (_userSelfie == null) ...[
              const Icon(Icons.camera_front, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _takeSelfie,
                child: const Text('Tómate una foto para probarte la ropa'),
              ),
            ] else ...[
              if (_isGenerating) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Enviando selfie a FAL.ai...\nEste proceso puede tardar unos 10 a 15 segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else if (_generationComplete && _finalImageUrl != null) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 4),
                  ),
                  child: Image.network(_finalImageUrl!, height: 350, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al Asesor'),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }
}
