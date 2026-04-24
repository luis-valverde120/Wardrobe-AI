import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

class CloudAIStylistService {
  /// Generates a fashion recommendation based on the occasion and available clothes.
  /// Can use a context image (e.g. photo of the event) if available.
  Future<Map<String, String>> generateOutfit({
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
          return "- ${item['id']}: ${item['name'] ?? 'Garment'}, Color: ${item['color'] ?? 'Unknown'}, Type: ${item['type'] ?? 'General'}";
        })
        .join('\n');

    final promptText =
        '''
You are an expert high-fashion stylist. Your job is to analyze the provided context (from the attached image or by inferring it) and recommend EXACTLY ONE GARMENT from the user's available clothing list so they can try it on in the virtual fitting room.

Available wardrobe items:
$clothesContext

Instructions:
1. Evaluate the weather, formality level, and style of the detected context.
2. Choose ONE upper-body garment (shirt, jacket, sweater) from the list that is the best option.
3. Return the results in STRICT JSON format. Do not include backticks or markdown, only the raw JSON. Exact format to return:
{
  "occasion": "Brief general description of the event/situation (e.g.: Formal evening wedding, Casual office wear)",
  "recommended_item_id": "Exact ID of the chosen item from the list",
  "description": "Your 2-3 line reasoning about why you chose this garment as ideal for the fitting room."
}
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
        final Map<String, dynamic> result = jsonDecode(cleanText);

        return {
          'occasion': result['occasion']?.toString() ?? 'Unknown Context',
          'recommended_item_id':
              result['recommended_item_id']?.toString() ?? '1',
          'description':
              result['description']?.toString() ?? 'Recommended outfit.',
        };
      } catch (e) {
        // Fallback in case Gemini returns something unexpected
        return {
          'occasion': 'Analysis completed',
          'recommended_item_id':
              availableClothes.first['id']?.toString() ?? '1',
          'description': text,
        };
      }
    } catch (e) {
      throw Exception('Error with the Gemini API: $e');
    }
  }
}
