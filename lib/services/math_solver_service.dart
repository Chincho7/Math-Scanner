import 'package:math_expressions/math_expressions.dart';

class MathSolverService {
  String solveMathProblem(String mathProblem) {
    try {
      // Convert LaTeX-like expressions to a format the parser can understand
      String processedExpression = _convertToEvaluableExpression(mathProblem);
      
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
      return 'Error: Unable to solve. Please check the format.';
    }
  }
  
  String _evaluateExpression(String expression) {
    try {
      // Parse and evaluate the expression
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      
      // Format result to remove trailing zeros after decimal point
      String resultString = result.toString();
      if (resultString.endsWith('.0')) {
        resultString = resultString.substring(0, resultString.length - 2);
      }
      
      return resultString;
    } catch (e) {
      print('Error evaluating expression: $e');
      return 'Error: Unable to evaluate $expression';
    }
  }
  
  String _convertToEvaluableExpression(String latexExpression) {
    // Remove spaces
    String expression = latexExpression.replaceAll(' ', '');
    
    // Replace LaTeX-style operations with standard math operations
    expression = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('\\cdot', '*')
        .replaceAll('\\times', '*')
        .replaceAll('\\div', '/')
        .replaceAll('{', '(')
        .replaceAll('}', ')')
        .replaceAll('\\frac', '') // Will need additional processing for fractions
        .replaceAll('\\sqrt', 'sqrt')
        .replaceAll('^', '^');
    
    // Handle special cases like fractions - this is a simple approach
    // A more comprehensive LaTeX parser would be needed for complex expressions
    if (expression.contains('sqrt')) {
      expression = expression.replaceAll('sqrt', 'sqrt');
    }
    
    // Remove any remaining LaTeX commands or characters that would cause parsing errors
    expression = expression.replaceAll('\\', '');
    
    return expression;
  }
}
