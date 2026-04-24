import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

class CloudAIStylistService {
  /// Generates multiple outfit suggestions based on the user's closet.
  /// Returns a JSON array with 3-4 outfit combinations, each with
  /// garment IDs, descriptions, and style tips.
  Future<List<Map<String, dynamic>>> generateMultipleOutfits({
    required List<Map<String, dynamic>> availableClothes,
    File? contextImage,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not configured in your .env file');
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    final String clothesContext = availableClothes
        .map((item) {
          return "- ID:${item['id']}, Name:${item['name'] ?? 'Garment'}, "
              "Color:${item['color'] ?? 'Unknown'}, "
              "Type:${item['type'] ?? 'General'}, "
              "Style:${item['style'] ?? 'N/A'}, "
              "Pattern:${item['pattern'] ?? 'N/A'}";
        })
        .join('\n');

    final promptText = '''
You are a world-class fashion stylist AI. Analyze the user's wardrobe and the context (from the attached image if available, or infer a general casual day context) to create 3 to 4 unique outfit suggestions.

Each outfit can use 1 to 3 garments combined. Prioritize variety: mix solo looks, layered looks, and different color combinations.

Available wardrobe items:
$clothesContext

Instructions:
1. Create 3-4 distinct outfit combinations using the items above.
2. For each outfit, pick the BEST primary garment (the one most visible — e.g., jacket over shirt means jacket is first in list).
3. Give each outfit a short creative name.
4. Write a brief description explaining why this combination works.
5. Add a "style_tip" with a specific color or accessory recommendation.
6. Return STRICT JSON only (no markdown, no backticks). Format:
[
  {
    "name": "Creative Outfit Name",
    "item_ids": ["id1", "id2"],
    "description": "2-3 sentences on why this combo works for the context.",
    "style_tip": "Specific advice like 'Pair with white sneakers and silver accessories for a clean finish.'"
  }
]
''';

    try {
      final List<Content> contentList = [];

      if (contextImage != null) {
        final imageBytes = await contextImage.readAsBytes();
        contentList.add(
          Content.multi([
            TextPart(promptText),
            DataPart('image/jpeg', imageBytes),
          ]),
        );
      } else {
        contentList.add(Content.text(promptText));
      }

      final response = await model.generateContent(contentList);
      final text = response.text ?? '';

      try {
        final cleanText = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> results = jsonDecode(cleanText);
        return results.cast<Map<String, dynamic>>();
      } catch (e) {
        // Fallback: return a single outfit with the first garment
        return [
          {
            'name': 'AI Pick',
            'item_ids': [availableClothes.first['id']?.toString() ?? '1'],
            'description': text,
            'style_tip': 'Try combining with neutral accessories.',
          }
        ];
      }
    } catch (e) {
      throw Exception('Error with the Gemini API: $e');
    }
  }

  /// Legacy single outfit generation (kept for backwards compatibility).
  Future<Map<String, String>> generateOutfit({
    required List<Map<String, dynamic>> availableClothes,
    File? contextImage,
  }) async {
    final results = await generateMultipleOutfits(
      availableClothes: availableClothes,
      contextImage: contextImage,
    );
    final first = results.first;
    return {
      'occasion': first['name']?.toString() ?? 'Unknown',
      'recommended_item_id':
          (first['item_ids'] as List?)?.first?.toString() ?? '1',
      'description': first['description']?.toString() ?? 'Recommended outfit.',
    };
  }
}
