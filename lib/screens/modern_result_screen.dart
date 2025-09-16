import 'package:flutter/material.dart';
import 'package:math_scanner/services/math_solver_service.dart';
import 'package:math_scanner/services/openai_service.dart';

class ModernResultScreen extends StatefulWidget {
  final String mathProblem;
  final String? imageSource;

  const ModernResultScreen({
    Key? key,
    required this.mathProblem,
    this.imageSource,
  }) : super(key: key);

  @override
  State<ModernResultScreen> createState() => _ModernResultScreenState();
}

class _ModernResultScreenState extends State<ModernResultScreen> {
  final MathSolverService _mathSolver = MathSolverService();
  final OpenAIService _openAIService = OpenAIService();
  
  String result = 'Calculating...';
  List<SolvingStep> steps = [];
  bool _isLoading = true;
  bool _useOpenAI = true;

  @override
  void initState() {
    super.initState();
    _solveProblem();
  }

  Future<void> _solveProblem() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_useOpenAI) {
        // Try OpenAI first for detailed step-by-step solutions
        final openAIResponse = await _openAIService.solveMathProblem(widget.mathProblem);
        if (mounted) {
          setState(() {
            result = _extractAnswer(openAIResponse);
            steps = _parseOpenAISteps(openAIResponse);
            _isLoading = false;
          });
        }
      } else {
        _fallbackToLocalSolver();
      }
    } catch (e) {
      print('OpenAI Error: $e');
      // Fallback to local solver if OpenAI fails
      _fallbackToLocalSolver();
    }
  }

  void _fallbackToLocalSolver() {
    try {
      final localResult = _mathSolver.solveMathProblem(widget.mathProblem);
      if (mounted) {
        setState(() {
          result = localResult;
          steps = _generateLocalSteps();
          _isLoading = false;
          _useOpenAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          result = 'Error: Could not solve problem';
          steps = [];
          _isLoading = false;
        });
      }
    }
  }

  String _extractAnswer(String openAIResponse) {
    // Try to extract the final answer from OpenAI response
    final lines = openAIResponse.split('\n');
    for (final line in lines.reversed) {
      if (line.toLowerCase().contains('answer') || line.contains('=')) {
        final match = RegExp(r'[=]\s*(-?\d+\.?\d*)').firstMatch(line);
        if (match != null) {
          return match.group(1) ?? result;
        }
      }
    }
    
    // If no clear answer found, try to calculate with local solver as backup
    try {
      return _mathSolver.solveMathProblem(widget.mathProblem);
    } catch (e) {
      return 'See steps below';
    }
  }

  List<SolvingStep> _parseOpenAISteps(String openAIResponse) {
    final List<SolvingStep> parsedSteps = [];
    final lines = openAIResponse.split('\n');
    
    String currentStep = '';
    String currentDescription = '';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Look for numbered steps or step indicators
      if (RegExp(r'^\d+\.|\bStep\s+\d+|\b(First|Next|Then|Finally)').hasMatch(line)) {
        if (currentStep.isNotEmpty) {
          parsedSteps.add(SolvingStep(
            title: currentStep,
            description: currentDescription,
            problem: widget.mathProblem,
            solution: result,
          ));
        }
        currentStep = line;
        currentDescription = '';
      } else {
        currentDescription += (currentDescription.isEmpty ? '' : '\n') + line;
      }
    }
    
    // Add the last step
    if (currentStep.isNotEmpty) {
      parsedSteps.add(SolvingStep(
        title: currentStep,
        description: currentDescription,
        problem: widget.mathProblem,
        solution: result,
      ));
    }
    
    // If no steps were parsed, create a basic step
    if (parsedSteps.isEmpty) {
      parsedSteps.add(SolvingStep(
        title: 'Solution',
        description: openAIResponse,
        problem: widget.mathProblem,
        solution: result,
      ));
    }
    
    return parsedSteps;
  }

  List<SolvingStep> _generateLocalSteps() {
    // Generate more detailed local steps with better explanations
    if (widget.mathProblem.contains('+')) {
      // For addition, break it down step by step
      List<String> numbers = widget.mathProblem.split('+').map((s) => s.trim()).toList();
      List<SolvingStep> detailedSteps = [];
      
      if (numbers.length > 2) {
        // Multi-number addition
        detailedSteps.add(SolvingStep(
          title: 'Identify the numbers to add',
          description: 'We have ${numbers.length} numbers: ${numbers.join(', ')}',
          problem: widget.mathProblem,
          solution: 'Numbers identified: ${numbers.join(' + ')}',
        ));
        
        // Step-by-step addition
        int runningSum = int.parse(numbers[0]);
        for (int i = 1; i < numbers.length; i++) {
          int nextNumber = int.parse(numbers[i]);
          int newSum = runningSum + nextNumber;
          detailedSteps.add(SolvingStep(
            title: 'Add step ${i}',
            description: 'Add $runningSum + $nextNumber',
            problem: '$runningSum + $nextNumber',
            solution: '$newSum',
          ));
          runningSum = newSum;
        }
      } else {
        // Simple two-number addition
        detailedSteps.add(SolvingStep(
          title: 'Add the two numbers',
          description: 'Adding ${numbers[0]} and ${numbers[1]} together',
          problem: '${numbers[0]} + ${numbers[1]}',
          solution: result,
        ));
      }
      
      return detailedSteps;
    } else if (widget.mathProblem.contains('-')) {
      return [
        SolvingStep(
          title: 'Subtract the numbers',
          description: 'Performing subtraction: ${widget.mathProblem}',
          problem: widget.mathProblem,
          solution: 'Result: $result',
        ),
      ];
    } else if (widget.mathProblem.contains('×') || widget.mathProblem.contains('*')) {
      return [
        SolvingStep(
          title: 'Multiply the numbers',
          description: 'Performing multiplication: ${widget.mathProblem}',
          problem: widget.mathProblem,
          solution: 'Product: $result',
        ),
      ];
    } else if (widget.mathProblem.contains('÷') || widget.mathProblem.contains('/')) {
      return [
        SolvingStep(
          title: 'Divide the numbers',
          description: 'Performing division: ${widget.mathProblem}',
          problem: widget.mathProblem,
          solution: 'Quotient: $result',
        ),
      ];
    }
    
    return [
      SolvingStep(
        title: 'Solve the expression',
        description: 'Mathematical calculation performed using order of operations',
        problem: widget.mathProblem,
        solution: 'Final result: $result',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Softer, more modern background
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Camera preview area (top third)
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                color: Colors.grey.shade200,
                child: Stack(
                  children: [
                    // Simulated camera background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade100],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    
                    // Problem text overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.mathProblem,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Close button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom sheet area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Solving Steps Header
                              Row(
                                children: [
                                  const Text(
                                    'SOLVING STEPS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD), // Soft blue background
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PLUS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2), // Blue accent
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Main solution title
                              const Text(
                                'Calculate the sum',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212529), // Darker, more readable
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Problem and edit button
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.mathProblem,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF212529), // Consistent dark color
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      // Edit functionality
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Enhanced step description with explanation
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'How we solved this:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _useOpenAI 
                                        ? 'Used AI-powered analysis to break down the problem step by step, ensuring accuracy and providing detailed explanations.'
                                        : 'Applied mathematical order of operations to solve ${widget.mathProblem}, processing each operation systematically.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5F6368),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Solution
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50), // Green accent
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _isLoading
                                    ? const SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF4CAF50), // Green loading indicator
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        result,
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF212529), // Consistent dark color
                                        ),
                                      ),
                                  if (!_isLoading && !_useOpenAI)
                                    Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E8), // Light green
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'LOCAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32), // Dark green
                                        ),
                                      ),
                                    ),
                                  if (!_isLoading && _useOpenAI)
                                    Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD), // Light blue
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'AI',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2), // Blue
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Show Solving Steps Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _showDetailedSteps(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoading ? Colors.grey.shade300 : const Color(0xFF1976D2), // Modern blue
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12), // More modern radius
                                    ),
                                    elevation: 2, // Subtle shadow
                                  ),
                                  child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Show Solving Steps',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward),
                                        ],
                                      ),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailedSteps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedStepsScreen(
          problem: widget.mathProblem,
          result: result,
          steps: steps,
        ),
      ),
    );
  }
}

class SolvingStep {
  final String title;
  final String description;
  final String problem;
  final String solution;

  SolvingStep({
    required this.title,
    required this.description,
    required this.problem,
    required this.solution,
  });
}

class DetailedStepsScreen extends StatelessWidget {
  final String problem;
  final String result;
  final List<SolvingStep> steps;

  const DetailedStepsScreen({
    Key? key,
    required this.problem,
    required this.result,
    required this.steps,
  }) : super(key: key);

  String _getOperationDescription() {
    if (problem.contains('+')) {
      return 'Add the numbers step by step';
    } else if (problem.contains('-')) {
      return 'Subtract the numbers';
    } else if (problem.contains('×') || problem.contains('*')) {
      return 'Multiply the numbers';
    } else if (problem.contains('÷') || problem.contains('/')) {
      return 'Divide the numbers';
    }
    return 'Solve the expression';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.red),
        ),
        title: const Text(
          'Solving Steps',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black54),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem with dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    problem,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _getOperationDescription(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Dynamic steps rendering
            ...steps.map((step) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.problem,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            )).toList(),
            
            // Solution section
            Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solution',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      result,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 80),
            
            // Feedback section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Did this explanation help you?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)), // Green border
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF4CAF50).withOpacity(0.1), // Light green background
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Thumbs up - show positive feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                                backgroundColor: Color(0xFF4CAF50),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.thumb_up_outlined,
                            size: 28,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)), // Red border
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF44336).withOpacity(0.1), // Light red background
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Thumbs down - show feedback form or message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('We appreciate your feedback and will improve!'),
                                backgroundColor: Color(0xFFF44336),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.thumb_down_outlined,
                            size: 28,
                            color: Color(0xFFF44336),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2), // Modern blue
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Modern radius
              ),
              elevation: 2,
            ),
            child: const Text(
              'Take Another Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
