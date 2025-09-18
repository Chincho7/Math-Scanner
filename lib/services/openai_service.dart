import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Get API key from environment variables
  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  
  /// Solve a math problem using OpenAI's GPT-4
  Future<String> solveMathProblem(String mathExpression) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenAI API key not found. Please check your .env file.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert mathematics tutor and problem solver. You provide clear, step-by-step solutions to mathematical problems at all levels, from basic arithmetic to advanced calculus, algebra, geometry, statistics, and beyond.

              Guidelines for your responses:
              1. **Always show your work step by step** - break down complex problems into manageable steps
              2. **Use clear mathematical notation** - but avoid excessive LaTeX formatting in explanations
              3. **Explain the reasoning** behind each step so students can learn
              4. **Provide the final answer clearly** - use simple formatting like "Final Answer: [result]"
              5. **Handle all types of problems**: arithmetic, algebra, geometry, calculus, statistics, word problems, etc.
              6. **For complex problems**: break them into sub-problems and solve systematically
              7. **For approximations**: explain when and why you're approximating
              8. **Verify your work** when possible by checking your answer
              
              For formatting:
              - Use **bold** for important steps or final answers
              - Use simple fractions like 2/3 instead of complex LaTeX
              - Use standard symbols: ≈ for approximately, ± for plus/minus, etc.
              - Keep mathematical expressions readable and clean
              
              If a problem seems ambiguous, ask for clarification or state your assumptions.'''
            },
            {
              'role': 'user',
              'content': 'Solve this math problem step by step: $mathExpression'
            }
          ],
          'max_tokens': 1500, // Increased for complex problems
          'temperature': 0.1, // Low temperature for consistent math solutions
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again in a moment.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error occurred';
        throw Exception('OpenAI API Error: $errorMessage');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Network error: Unable to connect to OpenAI. Please check your internet connection.');
    }
  }

  /// Validate if a math expression is solvable
  bool isValidMathExpression(String expression) {
    if (expression.isEmpty) return false;
    
    // More comprehensive validation for complex mathematical expressions
    final complexMathPattern = RegExp(r'^[0-9a-zA-Z+\-*/().,^√πesin cosθαβγδεφλμσωΔΣ\s=<>≤≥≠≈∫∂∇∞±∓∪∩∈∉⊂⊃∀∃∧∨¬→↔|!%]+$');
    
    // Also allow common math words and functions
    final hasValidMathContent = expression.toLowerCase().contains(RegExp(r'(solve|calculate|find|what|is|equals?|plus|minus|times|divided|multiply|add|subtract|derivative|integral|limit|sin|cos|tan|log|ln|sqrt|square|cube|power|root|percent|\d)'));
    
    return complexMathPattern.hasMatch(expression) || hasValidMathContent;
  }

  /// Generate a helpful error message for invalid expressions
  String getInvalidExpressionMessage(String expression) {
    if (expression.isEmpty) {
      return 'Please enter a math expression to solve.';
    }
    
    if (!isValidMathExpression(expression)) {
      return 'I can help with math problems including:\n• Basic arithmetic (2+2, 5*3)\n• Algebra (solve x+5=10)\n• Geometry (area of circle with radius 5)\n• Calculus (derivative of x²)\n• Word problems\n• And much more!';
    }
    
    return 'Unable to process this expression. Please check your math problem.';
  }
}
