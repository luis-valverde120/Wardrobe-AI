import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VTONService {
  final String _falApiUrl = 'https://fal.run/fal-ai/idm-vton';

  /// Llama a FAL.ai para realizar el Virtual Try-On
  /// Recibe la imagen de la persona y la imagen de la prenda (pueden ser URLs o Base64 Data URIs)
  Future<String> tryOn({
    required String humanImageUrl,
    required String garmentImageUrl,
    String description = '',
  }) async {
    final falKey = dotenv.env['FAL_KEY'];
    if (falKey == null || falKey.isEmpty) {
      throw Exception('FAL_KEY no está configurada en el archivo .env');
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
        // Fal.ai idm-vton retorna la imagen un arreglo 'image' o simplemente 'image' directamente dependiendo del schema exacto,
        // pero típicamente tiene "image": {"url": "..."}
        if (data['image'] != null && data['image']['url'] != null) {
          return data['image']['url'];
        } else {
          throw Exception('Estructura de respuesta inesperada desde Fal.ai');
        }
      } else {
        throw Exception('Error en Fal.ai: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Excepción al conectar con Fal.ai: $e');
    }
  }
}
