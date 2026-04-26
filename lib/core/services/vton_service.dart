import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VTONService {
  /// FLUX Kontext Pro — best Fal.ai model for image editing with
  /// identity preservation. Accepts image + text prompt.
  static const String _falApiUrl = 'https://fal.run/fal-ai/flux-pro/kontext';

  /// Calls Fal.ai FLUX Kontext Pro to perform the Virtual Try-On.
  /// Sends the user's photo and a descriptive prompt so the model
  /// adds the recommended clothes while keeping the person 100% identical.
  Future<String> tryOn({
    required String humanImageUrl,
    required String garmentImageUrl,
    String description = '',
  }) async {
    final falKey = dotenv.env['FAL_KEY'];
    if (falKey == null || falKey.isEmpty) {
      throw Exception('FAL_KEY is not configured in the .env file');
    }

    // Build a detailed prompt that instructs the model to keep the person
    // identical and only change/add the described clothing.
    final prompt =
        'Fotografía hiperrealista y de altísima calidad de esta misma persona vistiendo exactamente esto: $description. '
        'Mantener el rostro de la persona original 100% idéntico y la esencia de la imagen, '
        'pero integrar la ropa nueva de forma perfecta, natural y con estética visual de estudio fotográfico.';

    try {
      final requestBody = {
        "image_url": humanImageUrl,
        "prompt": prompt,
      };

      final response = await http.post(
        Uri.parse(_falApiUrl),
        headers: {
          'Authorization': 'Key $falKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // FLUX Kontext Pro returns: {"images": [{"url": "..."}], ...}
        if (data['images'] != null &&
            (data['images'] as List).isNotEmpty &&
            data['images'][0]['url'] != null) {
          return data['images'][0]['url'];
        } else {
          throw Exception('Unexpected response structure from Fal.ai');
        }
      } else {
        throw Exception(
            'Fal.ai error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Exception connecting to Fal.ai: $e');
    }
  }
}
