import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_scanner/services/math_solver_service.dart';
import 'package:math_scanner/services/openai_service.dart';

class ResultScreen extends StatefulWidget {
  final String mathProblem;
  final String? imageSource;

  const ResultScreen({
    super.key,
    required this.mathProblem,
    this.imageSource,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final MathSolverService _mathSolver = MathSolverService();
  final OpenAIService _openAIService = OpenAIService();
  
  String? _solution;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useOpenAI = true; // Flag to determine which service to use

  @override
  void initState() {
    super.initState();
    _solveMathProblem();
  }

  Future<void> _solveMathProblem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_useOpenAI && _openAIService.isValidMathExpression(widget.mathProblem)) {
        // Try OpenAI first
        final solution = await _openAIService.solveMathProblem(widget.mathProblem);
        setState(() {
          _solution = solution;
          _isLoading = false;
        });
      } else {
        // Fallback to local solver
        _fallbackToLocalSolver();
      }
    } catch (e) {
      print('OpenAI Error: $e');
      // If OpenAI fails, fallback to local solver
      _fallbackToLocalSolver();
    }
  }

  void _fallbackToLocalSolver() {
    try {
      final localSolution = _mathSolver.solveMathProblem(widget.mathProblem);
      setState(() {
        _solution = "Local Solution: $localSolution\n\n⚠️ For detailed step-by-step solutions, please check your internet connection and API configuration.";
        _isLoading = false;
        _useOpenAI = false;
      });
    } catch (e) {
      setState(() {
        _solution = null;
        _errorMessage = 'Unable to solve this problem. Please check the format and try again.';
        _isLoading = false;
      });
    }
  }

  void _retryWithOpenAI() {
    setState(() {
      _useOpenAI = true;
    });
    _solveMathProblem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Problem'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement sharing functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing not implemented yet')),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageSource != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imageSource!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Recognized Math Problem:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Math.tex(
                        widget.mathProblem,
                        textStyle: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Solution:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSolutionContent(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Plain Text:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.mathProblem,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Retry button if using local solver
            if (!_useOpenAI) ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: _retryWithOpenAI,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry with AI Solution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Scan Another Problem',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionContent() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Solving math problem...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _solveMathProblem,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_solution != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _useOpenAI ? Icons.psychology : Icons.calculate,
                color: _useOpenAI ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _useOpenAI ? 'AI-Powered Solution' : 'Local Solution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _useOpenAI ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _solution!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    return const Text(
      'No solution available.',
      style: TextStyle(fontSize: 16),
      textAlign: TextAlign.center,
    );
  }
}
