import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> recognizeTextFromPath(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    String text = recognizedText.text;
    
    // Clean up the text for math processing
    text = _cleanUpMathText(text);
    
    return text;
  }

  String _cleanUpMathText(String text) {
    // Remove extra whitespace
    String cleanedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Common OCR errors in math expressions
    Map<String, String> replacements = {
      'x': '×', // Replace x with multiplication sign
      '0': 'O', // Common OCR mistake
      'l': '1', // Lowercase L to 1
    };
    
    // Apply replacements
    replacements.forEach((key, value) {
      // Only replace when it makes sense in a math context
      // This is a simple example and would need more sophisticated logic
    });
    
    return cleanedText;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
