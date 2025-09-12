import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_scanner/screens/result_screen.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final MathFieldEditingController _mathController = MathFieldEditingController();
  String _displayedExpression = '';

  @override
  void dispose() {
    _mathController.dispose();
    super.dispose();
  }

  void _updateDisplayedExpression() {
    final newExpression = _mathController.currentEditingValue()?.toString() ?? '';
    // Only update if the math controller has content and it's different from what we have
    if (newExpression.isNotEmpty && newExpression != _displayedExpression) {
      setState(() {
        _displayedExpression = newExpression;
      });
    }
  }
  
  Widget _buildOperationButton(String operation) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (operation == '=') {
            _displayedExpression = (_displayedExpression.isEmpty ? '' : _displayedExpression) + '=';
          } else {
            // For other operations, append to the displayed expression
            _displayedExpression = (_displayedExpression.isEmpty ? '' : _displayedExpression) + operation;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(50, 50),
      ),
      child: Text(operation, style: const TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      alignment: Alignment.center,
                      child: _displayedExpression.isNotEmpty
                          ? Math.tex(
                              _displayedExpression,
                              textStyle: const TextStyle(fontSize: 22),
                            )
                          : const Text(
                              'Your math expression will appear here',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    MathField(
                      controller: _mathController,
                      keyboardType: MathKeyboardType.expression,
                      variables: const ['x', 'y', 'z'],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter math problem',
                      ),
                      onChanged: (value) {
                        _updateDisplayedExpression();
                      },
                    ),
                    const SizedBox(height: 10),
                    // Buttons for common operations
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildOperationButton('+'),
                        _buildOperationButton('-'),
                        _buildOperationButton('×'), // Multiplication
                        _buildOperationButton('÷'), // Division
                        _buildOperationButton('='),
                        _buildOperationButton('('),
                        _buildOperationButton(')'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_displayedExpression.isNotEmpty) {
                  // Use the displayed expression which may include the equals sign
                  String mathProblem = _displayedExpression;
                  
                  // Make sure the expression has an equals sign if it doesn't have one
                  if (!mathProblem.contains('=')) {
                    mathProblem += '=';
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        mathProblem: mathProblem,
                        imageSource: null,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a math problem'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Process Math Problem',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
