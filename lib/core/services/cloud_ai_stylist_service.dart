import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudAIStylistService {
  /// Fal.ai any-llm endpoint — uses FAL_KEY, no Gemini quota needed.
  static const String _falLlmUrl = 'https://fal.run/fal-ai/any-llm';

  /// LLM model to use via Fal.ai (Llama 4 Scout is fast and capable).
  static const String _llmModel = 'meta-llama/llama-4-scout';

  /// Generates multiple outfit suggestions based on the user's closet.
  /// Returns a JSON array with 3-4 outfit combinations, each with
  /// garment IDs, descriptions, and style tips.
  Future<List<Map<String, dynamic>>> generateMultipleOutfits({
    required List<Map<String, dynamic>> availableClothes,
    File? contextImage,
  }) async {
    final falKey = dotenv.env['FAL_KEY'];
    if (falKey == null || falKey.isEmpty) {
      throw Exception('FAL_KEY is not configured in your .env file');
    }

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
You are a world-class fashion stylist AI. Analyze the user's wardrobe to create 3 to 4 unique outfit suggestions.

Each outfit can use 1 to 3 garments combined. Prioritize variety: mix solo looks, layered looks, and different color combinations.

Available wardrobe items:
$clothesContext

Instructions:
1. Create 3-4 distinct outfit combinations using the items above.
2. For each outfit, pick the BEST primary garment (the one most visible — e.g., jacket over shirt means jacket is first in list).
3. Give each outfit a short creative name.
4. Write a brief description explaining why this combination works.
5. Add a "style_tip" with a specific color or accessory recommendation.
6. Return STRICT JSON only (no markdown, no backticks, no explanation). Format:
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
      final requestBody = {
        "prompt": promptText,
        "model": _llmModel,
        "temperature": 0.7,
        "max_tokens": 2048,
      };

      final response = await http.post(
        Uri.parse(_falLlmUrl),
        headers: {
          'Authorization': 'Key $falKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Fal.ai LLM error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      final outputText = data['output'] as String? ?? '';

      try {
        final cleanText = outputText
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
            'description': outputText,
            'style_tip': 'Try combining with neutral accessories.',
          }
        ];
      }
    } catch (e) {
      throw Exception('Error with the AI stylist: $e');
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
