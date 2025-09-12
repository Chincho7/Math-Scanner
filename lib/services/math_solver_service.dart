import 'package:math_expressions/math_expressions.dart';

class MathSolverService {
  String solveMathProblem(String mathProblem) {
    try {
      // Remove spaces and handle special characters
      String cleanedExpression = mathProblem
          .replaceAll(' ', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/');
      
      // Check if the expression already contains an equals sign
      if (cleanedExpression.contains('=')) {
        // For equations, we'll return the original input for now
        // since solving equations requires more complex handling
        return 'Equation detected: $mathProblem';
      }
      
      // Parse and evaluate the expression
      Parser p = Parser();
      Expression exp = p.parse(cleanedExpression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      
      // Format result to remove trailing zeros after decimal point
      String resultString = result.toString();
      if (resultString.endsWith('.0')) {
        resultString = resultString.substring(0, resultString.length - 2);
      }
      
      return resultString;
    } catch (e) {
      return 'Error: Unable to solve. Please check the format.';
    }
  }
}
