import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> recognizeTextFromPath(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Get raw text and detailed block information
    String text = recognizedText.text;
    
    print('Raw OCR Text: "$text"');
    
    // First, look for obvious simple math patterns in the raw text
    String directMathMatch = _findDirectMathPattern(text);
    if (directMathMatch.isNotEmpty) {
      print('Found direct math pattern: "$directMathMatch"');
      return directMathMatch;
    }
    
    // Try to extract math from individual text blocks for better accuracy
    String bestMathExpression = _extractMathFromBlocks(recognizedText);
    
    if (bestMathExpression.isNotEmpty) {
      print('Extracted from blocks: "$bestMathExpression"');
      return bestMathExpression;
    }
    
    // Fallback to full text processing
    text = _cleanUpMathText(text);
    print('Cleaned text: "$text"');
    
    return text;
  }

  String _findDirectMathPattern(String text) {
    // Look for very obvious math patterns first
    List<RegExp> simplePatterns = [
      RegExp(r'\b\d+\+\d+\+\d+\b'), // e.g., "2+9+8"
      RegExp(r'\b\d+\+\d+\b'), // e.g., "2+9"
      RegExp(r'\b\d+\-\d+\b'), // e.g., "9-2"  
      RegExp(r'\b\d+\*\d+\b'), // e.g., "3*4"
      RegExp(r'\b\d+\/\d+\b'), // e.g., "8/2"
    ];
    
    for (RegExp pattern in simplePatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String found = match.group(0)!;
        print('Direct pattern match found: "$found"');
        return found;
      }
    }
    
    return '';
  }

  String _extractMathFromBlocks(RecognizedText recognizedText) {
    List<String> potentialMathExpressions = [];
    
    // Process each text block separately for better accuracy
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.trim();
        print('Processing line: "$lineText"');
        
        // Look for mathematical patterns in each line - be more strict
        if (_looksLikeMath(lineText)) {
          String cleaned = _aggressiveCleanMath(lineText);
          print('Cleaned line "$lineText" to "$cleaned"');
          
          // Only accept if it's a valid, simple math expression
          if (cleaned.isNotEmpty && _isValidMathExpression(cleaned) && _isSimpleMathExpression(cleaned)) {
            print('Adding valid math expression: "$cleaned"');
            potentialMathExpressions.add(cleaned);
          } else {
            print('Rejected "$cleaned" - not a simple math expression');
          }
        }
      }
    }
    
    // Return the best math expression found
    if (potentialMathExpressions.isNotEmpty) {
      // Sort by length and mathematical complexity
      potentialMathExpressions.sort((a, b) {
        int scoreA = _scoreMathExpression(a);
        int scoreB = _scoreMathExpression(b);
        return scoreB.compareTo(scoreA);
      });
      return potentialMathExpressions.first;
    }
    
    return '';
  }

  bool _looksLikeMath(String text) {
    // Be very strict about what looks like math
    String cleaned = text.trim();
    
    // Reject if it contains non-math words or long text
    if (cleaned.length > 30) return false;
    if (cleaned.contains('September') || cleaned.contains('text') || 
        cleaned.contains('mob') || cleaned.contains('pub') ||
        cleaned.contains('app') || cleaned.contains('ca-') ||
        cleaned.contains('while') || cleaned.contains('create')) {
      return false;
    }
    
    // Must contain digits and operators, and be reasonably short
    bool hasDigit = RegExp(r'\d').hasMatch(cleaned);
    bool hasOperator = RegExp(r'[\+\-\×\÷\*\/]').hasMatch(cleaned);
    bool isShort = cleaned.length <= 15; // Simple math should be short
    
    // Extra check: should look like a simple arithmetic expression
    bool looksLikeSimpleArithmetic = RegExp(r'^\d+[\+\-\×\÷\*\/\d\s]*\d*$').hasMatch(cleaned.replaceAll(' ', ''));
    
    return hasDigit && hasOperator && isShort && looksLikeSimpleArithmetic;
  }

  int _scoreMathExpression(String expression) {
    int score = 0;
    score += RegExp(r'\d').allMatches(expression).length * 2; // Numbers are important
    score += RegExp(r'[\+\-\×\÷\*\/]').allMatches(expression).length * 3; // Operators are very important
    score += expression.length < 20 ? 5 : 0; // Prefer shorter expressions
    return score;
  }

  String _aggressiveCleanMath(String text) {
    // More aggressive cleaning for better number recognition
    String cleaned = text.trim();
    
    // First, reject obvious non-math patterns
    if (cleaned.contains('ca-app-pub') || cleaned.contains('ca-opp-pub')) {
      print('Rejecting ad ID pattern: "$cleaned"');
      return '';
    }
    
    // Handle common OCR misrecognitions
    cleaned = cleaned
        .replaceAll(RegExp(r'[Oo°]'), '0') // O, o, ° to 0
        .replaceAll(RegExp(r'[Il|!1]'), '1') // I, l, |, ! to 1
        .replaceAll(RegExp(r'[Ss$5]'), '5') // S, s, $ to 5
        .replaceAll(RegExp(r'[G6]'), '6') // G to 6
        .replaceAll(RegExp(r'[T7]'), '7') // T to 7
        .replaceAll(RegExp(r'[B8]'), '8') // B to 8
        .replaceAll(RegExp(r'[g9q]'), '9') // g, q to 9
        .replaceAll(RegExp(r'[Zz2]'), '2') // Z, z to 2
        .replaceAll(RegExp(r'[h4]'), '4') // h to 4
        .replaceAll(RegExp(r'[A4]'), '4') // A to 4
        .replaceAll('x', '*') // x to multiplication
        .replaceAll('×', '*') // × to *
        .replaceAll('÷', '/') // ÷ to /
        .replaceAll(':', '/') // : to /
        .replaceAll(RegExp(r'[^\d\+\-\*\/\(\)\.=\s]'), '') // Remove non-math chars
        .replaceAll(RegExp(r'\s+'), '') // Remove spaces
        .replaceAll(RegExp(r'=.*'), ''); // Remove everything after =
    
    // Final validation: if it contains suspicious patterns after cleaning, reject it
    if (cleaned.contains('820442') || cleaned.length > 15) {
      print('Rejecting suspicious pattern after cleaning: "$cleaned"');
      return '';
    }
    
    return cleaned.trim();
  }

  bool _isValidMathExpression(String expression) {
    if (expression.isEmpty || expression.length < 3) return false;
    
    // Must contain at least one number and one operator
    bool hasNumber = RegExp(r'\d').hasMatch(expression);
    bool hasOperator = RegExp(r'[\+\-\*\/]').hasMatch(expression);
    
    // Should not be just a single number
    bool isJustNumber = RegExp(r'^\d+$').hasMatch(expression);
    
    return hasNumber && hasOperator && !isJustNumber;
  }

  bool _isSimpleMathExpression(String expression) {
    // Additional validation for simple math expressions
    if (expression.isEmpty || expression.length > 20) return false;
    
    // Should not contain long sequences of same character
    if (RegExp(r'(.)\1{3,}').hasMatch(expression)) return false; // e.g., "----" or "0000"
    
    // Should not contain complex patterns that look like IDs
    if (expression.contains('820442') || expression.contains('pub') || 
        expression.contains('app') || expression.contains('ca-')) {
      return false;
    }
    
    // Should be a simple arithmetic expression pattern
    bool simplePattern = RegExp(r'^\d+[\+\-\*\/]\d+(\+\d+)*$|^\d+(\+\d+)+$|^\d+[\+\-\*\/]\d+$').hasMatch(expression);
    
    return simplePattern;
  }

  String _cleanUpMathText(String text) {
    // Fallback method when block-level extraction fails
    print('Fallback cleaning for: "$text"');
    
    // Remove extra whitespace and normalize
    String cleanedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Extract math expressions from the text using improved regex
    List<String> mathExpressions = [];
    
    // Multiple patterns to catch different math formats
    List<RegExp> mathPatterns = [
      RegExp(r'\d+[\+\-\×\÷\*\/]\d+[\+\-\×\÷\*\/\d]*'), // 2+3+4 pattern
      RegExp(r'\d+[\s]*[\+\-\×\÷\*\/][\s]*\d+'), // 2 + 3 pattern
      RegExp(r'[\d\s\+\-\×\÷\*\/\(\)\.=]+'), // General math pattern
    ];
    
    for (RegExp pattern in mathPatterns) {
      Iterable<Match> matches = pattern.allMatches(cleanedText);
      for (Match match in matches) {
        String expr = _aggressiveCleanMath(match.group(0)!);
        if (expr.length > 2 && _isValidMathExpression(expr)) {
          mathExpressions.add(expr);
        }
      }
    }
    
    // If we found math expressions, use the best one
    if (mathExpressions.isNotEmpty) {
      mathExpressions.sort((a, b) => _scoreMathExpression(b).compareTo(_scoreMathExpression(a)));
      cleanedText = mathExpressions.first;
    } else {
      // Last resort: aggressive cleaning of the entire text
      cleanedText = _aggressiveCleanMath(cleanedText);
    }
    
    print('Final cleaned text: "$cleanedText"');
    return cleanedText;
  }
  
  bool _containsMathOperator(String text) {
    return text.contains('+') || 
           text.contains('-') || 
           text.contains('×') || 
           text.contains('÷') || 
           text.contains('*') || 
           text.contains('/') ||
           text.contains('=');
  }

  void dispose() {
    _textRecognizer.close();
  }
}
