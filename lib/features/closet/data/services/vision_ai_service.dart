import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class VisionAiService {
  late final GenerativeModel _model;

  VisionAiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY is not defined in .env');
    }
    // gemini-1.5-flash es rápido, barato y multimodal. Ideal para esta tarea.
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Analiza la imagen de una prenda y extrae etiquetas (categoría, color, etc.)
  Future<Map<String, String>> analyzeClothing(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    
    // Asumimos PNG porque el segmentador debería devolver un PNG para mantener transparencia
    final imagePart = DataPart('image/png', imageBytes);

    final prompt = TextPart('''
Actúa como un experto en moda. Analiza esta prenda de ropa y devuelve estrictamente un objeto JSON con los siguientes campos:
- "category": La categoría principal (ej: "Camiseta", "Pantalón", "Zapatos", "Chaqueta", "Vestido", "Falda", "Sudadera", "Accesorio").
- "color": El color predominante (ej: "Negro", "Azul", "Rojo", "Beige").
- "pattern": El patrón de la tela (ej: "Sólido", "Rayas", "Cuadros", "Floral", "Textura").
- "style": El estilo (ej: "Casual", "Formal", "Deportivo", "Elegante", "Urbano").
- "season": La estación ideal (ej: "Verano", "Invierno", "Media Estación", "Todas").
- "ai_description": Una descripción breve, de la prenda en si. Máximo 10 palabras.
No incluyas etiquetas markdown como ```json o ```, responde SOLO texto plano que empiece con { y termine con }.
''');

    try {
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final rawText = response.text ?? '{}';
      final cleanedText = rawText.replaceAll(RegExp(r'```[a-z]*\n'), '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> data = jsonDecode(cleanedText);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error parsing Gemini JSON: $e');
      // Fallback response
      return {
        'category': 'Desconocido',
        'color': 'Desconocido',
        'pattern': 'Desconocido',
        'style': 'Desconocido',
        'season': 'Desconocido',
        'ai_description': 'Análisis fallido.'
      };
    }
  }
}
