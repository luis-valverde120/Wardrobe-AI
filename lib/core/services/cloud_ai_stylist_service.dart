import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

class CloudAIStylistService {
  /// Genera una recomendación de moda basada en la ocasión y ropa disponible.
  /// Puede usar una imagen de contexto (ej. foto del evento) si está disponible.
  Future<Map<String, String>> generateOutfit({
    required List<Map<String, dynamic>> availableClothes,
    File? contextImage,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('La GEMINI_API_KEY no está configurada en tu archivo .env');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final String clothesContext = availableClothes.map((item) {
      return "- \${item['id']}: \${item['name'] ?? 'Prenda'}, Color: \${item['color'] ?? 'Desconocido'}, Tipo: \${item['type'] ?? 'General'}";
    }).join('\n');

    final promptText = '''
Eres un estilista experto de alta costura. Tu trabajo es analizar el contexto proporcionado (a partir de la imagen adjunta o infiriéndolo) y recomendar EXACTAMENTE UNA PRENDA de la lista de ropa disponible del usuario para que se la pruebe frente al espejo.

Ropa en el armario:
$clothesContext

Instrucciones:
1. Evalúa el clima, nivel de formalidad y estilo del contexto detectado.
2. Escoge UNA prenda superior (camisa, chaqueta, suéter) de la lista que sea la mejor opción.
3. Devuelve los resultados en ESTRICTO formato JSON. No incluyas backticks (\`\`\`) ni markdown, solo el JSON raw. Formato exacto a devolver:
{
  "occasion": "Breve descripción general del evento/situación (ej: Boda formal de noche, Casual de oficina)",
  "recommended_item_id": "ID exacto del item escogido de la lista",
  "description": "Tu razonamiento de 2 o 3 líneas sobre por qué escogiste esta prenda como la ideal para el probador."
}
''';

    try {
      final List<Content> contentList = [];
      
      if (contextImage != null) {
        final imageBytes = await contextImage.readAsBytes();
        contentList.add(Content.multi([
          TextPart(promptText),
          DataPart('image/jpeg', imageBytes),
        ]));
      } else {
        contentList.add(Content.text(promptText));
      }

      final response = await model.generateContent(contentList);
      final text = response.text ?? '';
      
      try {
        final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> result = jsonDecode(cleanText);
        
        return {
          'occasion': result['occasion']?.toString() ?? 'Contexto Desconocido',
          'recommended_item_id': result['recommended_item_id']?.toString() ?? '1',
          'description': result['description']?.toString() ?? 'Outfit recomendado.',
        };
      } catch (e) {
        // Fallback en caso de que Gemini devuelva algo rarísimo
        return {
          'occasion': 'Análisis completado',
          'recommended_item_id': availableClothes.first['id']?.toString() ?? '1',
          'description': text,
        };
      }
    } catch (e) {
      throw Exception('Hubo un error con la API de Gemini: $e');
    }
  }
}
