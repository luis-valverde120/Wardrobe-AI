import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VTONService {
  final String _falApiUrl = 'https://fal.run/fal-ai/idm-vton';

  /// Calls FAL.ai to perform the Virtual Try-On.
  /// Receives the person's image and the garment image (can be URLs or Base64 Data URIs).
  Future<String> tryOn({
    required String humanImageUrl,
    required String garmentImageUrl,
    String description = '',
  }) async {
    final falKey = dotenv.env['FAL_KEY'];
    if (falKey == null || falKey.isEmpty) {
      throw Exception('FAL_KEY is not configured in the .env file');
    }

    try {
      final requestBody = {
        "human_image_url": humanImageUrl,
        "garment_image_url": garmentImageUrl,
        "description": description,
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
        // Fal.ai idm-vton returns the image typically as {"image": {"url": "..."}}
        if (data['image'] != null && data['image']['url'] != null) {
          return data['image']['url'];
        } else {
          throw Exception('Unexpected response structure from Fal.ai');
        }
      } else {
        throw Exception('Fal.ai error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Exception connecting to Fal.ai: $e');
    }
  }
}
