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
    setState(() {
      _displayedExpression = _mathController.currentEditingValue()?.toString() ?? '';
    });
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
                    // Custom button for equals sign
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Add equals sign to the expression
                            final currentValue = _mathController.currentEditingValue()?.toString() ?? '';
                            _mathController.setEditingValue(currentValue + '=');
                            _updateDisplayedExpression();
                          },
                          child: const Text('=', style: TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_mathController.currentEditingValue() != null) {
                  final String mathProblem = _mathController.currentEditingValue().toString();
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
