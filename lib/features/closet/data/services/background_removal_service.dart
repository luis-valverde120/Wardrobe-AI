import 'dart:io';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  final _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundBitmap: false,
      enableForegroundConfidenceMask: true,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    ),
  );

  /// Toma la imagen origen, extrae la máscara y recorta el fondo, devolviendo
  /// un nuevo archivo PNG con fondo transparente.
  Future<File?> removeBackground(File inputImageFile) async {
    try {
      final inputImage = InputImage.fromFile(inputImageFile);
      final SubjectSegmentationResult result = await _segmenter.processImage(
        inputImage,
      );

      // Leemos la imagen original usando el package "image"
      final img.Image? originalImage = img.decodeImage(
        await inputImageFile.readAsBytes(),
      );
      if (originalImage == null) return null;

      final maskBits = result.foregroundConfidenceMask;
      if (maskBits == null) {
        // No se detectó sujeto
        return inputImageFile;
      }

      final int width = originalImage.width;
      final int height = originalImage.height;

      // Aplicamos la máscara píxel por píxel
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // El buffer es un array 1D de floats (o UInt8 dependiendo de la API de ML Kit).
          // En ML Kit Dart, foregroundConfidenceMask es un buffer de floats [0.0 - 1.0]
          final int index = y * width + x;
          final double confidence = maskBits[index];

          if (confidence < 0.5) {
            // Es fondo, lo hacemos transparente
            originalImage.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      // Guardamos la imagen resultante como PNG para preservar la transparencia
      final tempDir = await getTemporaryDirectory();
      final outputFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final pngBytes = img.encodePng(originalImage);
      await outputFile.writeAsBytes(pngBytes);

      return outputFile;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _segmenter.close();
  }
}
