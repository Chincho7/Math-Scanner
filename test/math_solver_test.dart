import 'package:flutter_test/flutter_test.dart';
import 'package:math_scanner/services/math_solver_service.dart';

void main() {
  group('MathSolverService Tests', () {
    late MathSolverService mathSolver;

    setUp(() {
      mathSolver = MathSolverService();
    });

    test('should solve simple addition', () {
      String result = mathSolver.solveMathProblem('2+9+8');
      expect(result, '19');
    });

    test('should solve simple subtraction', () {
      String result = mathSolver.solveMathProblem('10-5');
      expect(result, '5');
    });

    test('should solve simple multiplication', () {
      String result = mathSolver.solveMathProblem('3*4');
      expect(result, '12');
    });

    test('should solve simple division', () {
      String result = mathSolver.solveMathProblem('8/2');
      expect(result, '4');
    });

    test('should handle expressions with spaces', () {
      String result = mathSolver.solveMathProblem('2 + 9 + 8');
      expect(result, '19');
    });

    test('should handle expressions with × symbol', () {
      String result = mathSolver.solveMathProblem('5×3');
      expect(result, '15');
    });

    test('should handle mixed operations', () {
      String result = mathSolver.solveMathProblem('2+3*4');
      expect(result, '14');
    });
  });
}
