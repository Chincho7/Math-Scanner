import 'package:math_expressions/math_expressions.dart';

class MathSolverService {
  String solveMathProblem(String mathProblem) {
    try {
      // Clean the input first
      String cleanedInput = mathProblem.trim();
      
      // Remove any non-math characters and normalize
      cleanedInput = _preCleanExpression(cleanedInput);
      
      print('Original: $mathProblem');
      print('Cleaned: $cleanedInput');
      
      // If empty after cleaning, return error
      if (cleanedInput.isEmpty) {
        return 'Error: No valid math expression found';
      }
      
      // Try simple evaluation first for basic expressions
      String simpleResult = _trySimpleEvaluation(cleanedInput);
      if (simpleResult != 'COMPLEX') {
        print('Simple evaluation result: $simpleResult');
        return simpleResult;
      }
      
      // Convert LaTeX-like expressions to a format the parser can understand
      String processedExpression = _convertToEvaluableExpression(cleanedInput);
      print('Processed: $processedExpression');
      
      // Check if the expression already contains an equals sign
      if (processedExpression.contains('=')) {
        // Extract the part before the equals sign for calculation
        String expressionPart = processedExpression.split('=').first.trim();
        if (expressionPart.isNotEmpty) {
          return _evaluateExpression(expressionPart);
        } else {
          return 'Error: Invalid equation format';
        }
      }
      
      // Evaluate the expression
      return _evaluateExpression(processedExpression);
    } catch (e) {
      print('Error solving math problem: $e');
      // Try a fallback simple evaluation
      return _simpleFallbackEvaluation(mathProblem);
    }
  }
  
  String _preCleanExpression(String expression) {
    print('Pre-cleaning: "$expression"');
    
    // More aggressive OCR error correction
    String cleaned = expression
        .replaceAll(RegExp(r'[Oo°]'), '0') // O, o, ° to 0
        .replaceAll(RegExp(r'[Il|!]'), '1') // I, l, |, ! to 1
        .replaceAll(RegExp(r'[Ss$]'), '5') // S, s, $ to 5
        .replaceAll(RegExp(r'[G]'), '6') // G to 6
        .replaceAll(RegExp(r'[T]'), '7') // T to 7
        .replaceAll(RegExp(r'[B]'), '8') // B to 8
        .replaceAll(RegExp(r'[gq]'), '9') // g, q to 9
        .replaceAll(RegExp(r'[Zz]'), '2') // Z, z to 2
        .replaceAll(RegExp(r'[h]'), '4') // h to 4
        .replaceAll(RegExp(r'[A]'), '4') // A to 4
        .replaceAll('x', '*') // x to multiplication
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(':', '/') // colon to division
        .replaceAll(RegExp(r'[^\d\+\-\*\/\(\)\.\s]'), '') // Keep only math chars
        .replaceAll(RegExp(r'\s+'), ''); // Remove all spaces
    
    // Remove leading/trailing operators
    cleaned = cleaned.replaceAll(RegExp(r'^[\+\-\*\/]+|[\+\-\*\/]+$'), '');
    
    // Fix double operators (e.g., "2++3" -> "2+3")
    cleaned = cleaned.replaceAll(RegExp(r'[\+\-\*\/]{2,}'), '+');
    
    print('Pre-cleaned result: "$cleaned"');
    return cleaned;
  }
  
  String _trySimpleEvaluation(String expression) {
    // Handle very simple cases directly with better patterns
    try {
      print('Trying simple evaluation for: "$expression"');
      
      // Simple addition (e.g., "2+9+8", "2+3+4+5")
      if (RegExp(r'^\d+(\+\d+)+$').hasMatch(expression)) {
        print('Detected simple addition pattern');
        List<String> parts = expression.split('+');
        double sum = 0;
        for (String part in parts) {
          if (part.isNotEmpty) {
            sum += double.parse(part);
          }
        }
        String result = sum % 1 == 0 ? sum.toInt().toString() : sum.toString();
        print('Simple addition result: $result');
        return result;
      }
      
      // Simple subtraction (e.g., "10-3")
      if (RegExp(r'^\d+-\d+$').hasMatch(expression)) {
        print('Detected simple subtraction pattern');
        List<String> parts = expression.split('-');
        if (parts.length == 2 && parts[1].isNotEmpty) {
          double result = double.parse(parts[0]) - double.parse(parts[1]);
          String resultStr = result % 1 == 0 ? result.toInt().toString() : result.toString();
          print('Simple subtraction result: $resultStr');
          return resultStr;
        }
      }
      
      // Simple multiplication (e.g., "3*4", "2*5")
      if (RegExp(r'^\d+\*\d+$').hasMatch(expression)) {
        print('Detected simple multiplication pattern');
        List<String> parts = expression.split('*');
        if (parts.length == 2) {
          double result = double.parse(parts[0]) * double.parse(parts[1]);
          String resultStr = result % 1 == 0 ? result.toInt().toString() : result.toString();
          print('Simple multiplication result: $resultStr');
          return resultStr;
        }
      }
      
      // Simple division (e.g., "8/2", "10/5")
      if (RegExp(r'^\d+\/\d+$').hasMatch(expression)) {
        print('Detected simple division pattern');
        List<String> parts = expression.split('/');
        if (parts.length == 2 && parts[1] != '0') {
          double result = double.parse(parts[0]) / double.parse(parts[1]);
          String resultStr = result % 1 == 0 ? result.toInt().toString() : result.toString();
          print('Simple division result: $resultStr');
          return resultStr;
        }
      }
      
      // Mixed simple operations (e.g., "2+3*4")
      if (RegExp(r'^\d+[\+\-\*\/]\d+[\+\-\*\/]\d+$').hasMatch(expression)) {
        print('Detected simple mixed operations pattern');
        // For simple three-number expressions, use order of operations
        return _evaluateSimpleThreeNumber(expression);
      }
      
    } catch (e) {
      print('Error in simple evaluation: $e');
    }
    
    return 'COMPLEX';
  }
  
  String _evaluateSimpleThreeNumber(String expression) {
    try {
      // Handle simple three-number expressions with proper order of operations
      // E.g., "2+3*4" should be 2+(3*4)=14, not (2+3)*4=20
      
      // First handle multiplication and division
      String temp = expression;
      
      // Find multiplication
      RegExp multPattern = RegExp(r'(\d+)\*(\d+)');
      Match? multMatch = multPattern.firstMatch(temp);
      if (multMatch != null) {
        double result = double.parse(multMatch.group(1)!) * double.parse(multMatch.group(2)!);
        temp = temp.replaceFirst(multPattern, result.toInt().toString());
      }
      
      // Find division
      RegExp divPattern = RegExp(r'(\d+)\/(\d+)');
      Match? divMatch = divPattern.firstMatch(temp);
      if (divMatch != null) {
        double result = double.parse(divMatch.group(1)!) / double.parse(divMatch.group(2)!);
        temp = temp.replaceFirst(divPattern, result % 1 == 0 ? result.toInt().toString() : result.toString());
      }
      
      // Now handle addition and subtraction from left to right
      return _trySimpleEvaluation(temp); // Recursively evaluate the simplified expression
      
    } catch (e) {
      print('Error in three-number evaluation: $e');
      return 'COMPLEX';
    }
  }

  String _convertToEvaluableExpression(String expression) {
    // Convert common mathematical notation to evaluable format
    String converted = expression;
    
    // Handle implicit multiplication (e.g., "2(3+4)" -> "2*(3+4)")
    converted = converted.replaceAll(RegExp(r'(\d)(\()'), r'$1*$2');
    converted = converted.replaceAll(RegExp(r'(\))(\d)'), r'$1*$2');
    
    // Handle fractions if detected
    if (converted.contains('/') && !converted.contains('(')) {
      // Simple fraction handling
      converted = converted;
    }
    
    return converted;
  }

  String _evaluateExpression(String expression) {
    try {
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      
      // Return integer if it's a whole number, otherwise return decimal
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        return result.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
      }
    } catch (e) {
      print('Math expression evaluation failed: $e');
      return _simpleFallbackEvaluation(expression);
    }
  }

  String _simpleFallbackEvaluation(String expression) {
    try {
      // Very basic fallback for simple operations
      String cleaned = expression.replaceAll(RegExp(r'[^\d\+\-\*\/\(\)]'), '');
      
      if (cleaned.contains('+') && !cleaned.contains('*') && !cleaned.contains('/') && !cleaned.contains('-')) {
        // Simple addition only
        List<String> parts = cleaned.split('+');
        double sum = 0;
        for (String part in parts) {
          if (part.isNotEmpty) {
            sum += double.parse(part);
          }
        }
        return sum.toInt().toString();
      }
      
      return 'Error: Could not evaluate expression';
    } catch (e) {
      print('Fallback evaluation failed: $e');
      return 'Error: Invalid math expression';
    }
  }

  // Helper method to generate step-by-step solutions
  List<String> generateSteps(String mathProblem) {
    List<String> steps = [];
    
    try {
      String cleaned = _preCleanExpression(mathProblem);
      steps.add('Step 1: Clean the expression: "$mathProblem" → "$cleaned"');
      
      String result = _trySimpleEvaluation(cleaned);
      if (result != 'COMPLEX') {
        steps.add('Step 2: Evaluate: $cleaned = $result');
      } else {
        steps.add('Step 2: Use advanced evaluation for: $cleaned');
        String finalResult = _evaluateExpression(cleaned);
        steps.add('Step 3: Result: $finalResult');
      }
    } catch (e) {
      steps.add('Error generating steps: $e');
    }
    
    return steps;
  }
}
