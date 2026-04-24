import 'dart:convert';
import 'package:http/http.dart' as http;

class AIStylistService {
  // Use '10.0.2.2' if testing on Android Emulator
  // Use '127.0.0.1' or 'localhost' if testing on Windows/Web/iOS Simulator
  final String _baseUrl = 'http://127.0.0.1:11434/api/generate';
  final String _model = 'gemma';

  /// Generates a fashion recommendation and an image prompt based on the occasion and available clothes.
  Future<Map<String, String>> generateOutfit({
    required String occasion,
    required List<Map<String, dynamic>> availableClothes,
  }) async {
    final String clothesContext = availableClothes.map((item) {
      return "- ${item['name'] ?? 'Prenda'}, Color: ${item['color'] ?? 'Desconocido'}, Tipo: ${item['type'] ?? 'General'}";
    }).join('\n');

    final String prompt = '''
Eres un estilista experto de alta costura y asesor de imagen personal.
Analiza la siguiente ocasión y la ropa disponible del usuario para crear el outfit perfecto.

Ocasión/Ambiente: $occasion

Ropa en el armario:
$clothesContext

Aplica reglas de moda (ej. no jeans en eventos formales, contraste de colores, reglas de texturas).
Debes devolver la respuesta estrictamente en este formato JSON:
{
  "description": "Una descripción detallada y profesional del outfit, explicando el por qué de cada elección.",
  "image_prompt": "A highly detailed image generation prompt in ENGLISH describing a person wearing this exact outfit. Include lighting, mood, photorealistic. Do NOT include the face details."
}
No devuelvas nada más que el JSON puro válido.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': false,
          'format': 'json',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String generatedText = data['response'];
        
        try {
          final Map<String, dynamic> result = jsonDecode(generatedText);
          return {
            'description': result['description'] ?? 'Resultados generados sin descripción.',
            'image_prompt': result['image_prompt'] ?? 'photo of a person modeling an outfit',
          };
        } catch (e) {
          // Fallback if LLM failed to return valid JSON
          return {
            'description': generatedText,
            'image_prompt': 'a person wearing a fashionable outfit for $occasion, photorealistic, 8k, full body',
          };
        }
      } else {
        throw Exception('Failed to connect to Ollama: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling AI: $e');
    }
  }
}
