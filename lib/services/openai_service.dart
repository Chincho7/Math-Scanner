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
              'content': '''You are a math tutor that provides step-by-step solutions to math problems. 
              Please:
              1. Solve the math problem step by step
              2. Show your work clearly
              3. Provide the final answer
              4. Keep explanations clear and educational
              5. If the expression is invalid, explain what's wrong and suggest corrections'''
            },
            {
              'role': 'user',
              'content': 'Solve this math problem step by step: $mathExpression'
            }
          ],
          'max_tokens': 1000,
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
    
    // Basic validation - contains mathematical characters
    final mathPattern = RegExp(r'^[0-9+\-*/().x^√π\s=]+$');
    return mathPattern.hasMatch(expression) && expression.length > 0;
  }

  /// Generate a helpful error message for invalid expressions
  String getInvalidExpressionMessage(String expression) {
    if (expression.isEmpty) {
      return 'Please enter a math expression to solve.';
    }
    
    if (!isValidMathExpression(expression)) {
      return 'The expression contains invalid characters. Please use only numbers and math symbols (+, -, *, /, ^, √, π, parentheses).';
    }
    
    return 'Unable to process this expression. Please check your math problem.';
  }
}
