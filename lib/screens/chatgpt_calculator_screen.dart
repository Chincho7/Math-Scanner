import 'package:flutter/material.dart';
import 'package:math_scanner/services/math_solver_service.dart';
import 'package:math_scanner/services/openai_service.dart';
import 'package:math_scanner/services/calculator_history_service.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? calculation;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.calculation,
  });
}

class ChatGPTCalculatorScreen extends StatefulWidget {
  const ChatGPTCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<ChatGPTCalculatorScreen> createState() => _ChatGPTCalculatorScreenState();
}

class _ChatGPTCalculatorScreenState extends State<ChatGPTCalculatorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MathSolverService _mathSolver = MathSolverService();
  final OpenAIService _openAIService = OpenAIService();
  final CalculatorHistoryService _historyService = CalculatorHistoryService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      content: "Hi! I'm your AI math assistant. You can ask me to solve math problems, explain concepts, or help with calculations. Try typing something like '2+9+8' or 'What is 15% of 200?'",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Quick local calculation attempt
      final localCalc = _mathSolver.solveMathProblem(userMessage);

      // Ask OpenAI for step-by-step explanation
      String aiText;
      try {
        // Optional debug prints
        // ignore: avoid_print
        print('Sending to OpenAI: $userMessage');
        aiText = await _openAIService.solveMathProblem(userMessage);
        // ignore: avoid_print
        print('OpenAI response: $aiText');
      } catch (e) {
        aiText = 'Here is a quick result: $localCalc';
      }

      final calc = _extractCalculation(aiText) ?? _tryParseNumber(localCalc);

      setState(() {
        _messages.add(ChatMessage(
          content: aiText,
          isUser: false,
          timestamp: DateTime.now(),
          calculation: calc,
        ));
        _isLoading = false;
      });

      await _historyService.saveCalculation(
        question: userMessage,
        answer: aiText,
        calculation: calc,
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Sorry, I had trouble solving that. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String? _extractCalculation(String text) {
    // Try \boxed{...}
    final boxed = RegExp(r'\\boxed\{([+-]?\d+(?:\.\d+)?)\}');
    final m1 = boxed.firstMatch(text);
    if (m1 != null) return m1.group(1);
    // Try the last standalone number in the text
    final numbers = RegExp(r'[-+]?\d+(?:\.\d+)?').allMatches(text).toList();
    if (numbers.isNotEmpty) return numbers.last.group(0);
    return null;
  }

  String? _tryParseNumber(String s) {
    final trimmed = s.trim();
    if (RegExp(r'^[-+]?\d+(?:\.\d+)?$').hasMatch(trimmed)) return trimmed;
    return null;
  }
  
  bool _containsMathSymbols(String text) {
    return text.contains('+') || 
           text.contains('-') || 
           text.contains('*') || 
           text.contains('/') || 
           text.contains('×') || 
           text.contains('÷');
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _insertQuickExpression(String expression) {
    _messageController.text = expression;
  }
  
  void _clearHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to clear all calculation history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _historyService.clearHistory();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  void _showHistorySheet() async {
    final history = await _historyService.getHistory();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculation History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _clearHistory,
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Clear History',
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No calculation history yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return _buildHistoryItem(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHistoryItem(CalculatorHistory item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                _formatHistoryTime(item.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (item.calculation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Result: ${item.calculation}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _insertQuickExpression(item.question);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Use this calculation',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatHistoryTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Calculator Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _showHistorySheet,
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_chat':
                  setState(() {
                    _messages.clear();
                    _addWelcomeMessage();
                  });
                  break;
                case 'clear_history':
                  _clearHistory();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick calculation buttons
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickButton('2+2'),
                  _buildQuickButton('10*5'),
                  _buildQuickButton('100/4'),
                  _buildQuickButton('15%'),
                  _buildQuickButton('√16'),
                  _buildQuickButton('2³'),
                ],
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask me to solve a math problem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _insertQuickExpression(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.calculate,
                size: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(
                    message.content,
                    message.isUser ? Colors.white : Colors.black87,
                  ),
                  if (message.calculation != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Result: ${message.calculation}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(
              Icons.calculate,
              size: 16,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Calculating...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormattedText(String text, Color textColor) {
    // High-level formatter that renders:
    // - Headings (###, ##, #)
    // - Bullet lists (-, *)
    // - Math blocks (\[ ... \]) as centered, larger text
    // - Inline bold (**text**)
    // - Common LaTeX -> readable symbols
    final lines = text.split('\n');
    final children = <Widget>[];
    bool inMathBlock = false;
    final mathBuffer = StringBuffer();

    // Choose a math block background that works on light/dark bubbles
    Color mathBgColor;
    try {
      mathBgColor = textColor.computeLuminance() > 0.5
          ? Colors.white.withOpacity(0.15)
          : (Colors.grey[100] ?? Colors.black.withOpacity(0.05));
    } catch (_) {
      mathBgColor = Colors.grey[100] ?? Colors.black.withOpacity(0.05);
    }

    void addSpacing([double h = 8]) {
      if (children.isNotEmpty && children.last is! SizedBox) {
        children.add(SizedBox(height: h));
      }
    }

    void flushMath() {
      if (mathBuffer.isEmpty) return;
      var math = mathBuffer.toString().trim();
      // Remove LaTeX block markers and box commands
      math = math.replaceAll(RegExp(r'^\\\[\s*'), '');
      math = math.replaceAll(RegExp(r'\s*\\\]$'), '');
      math = math.replaceAllMapped(RegExp(r'\\boxed\{([^}]+)\}'), (m) => m.group(1)!);
      math = _formatMathExpressions(math);

      addSpacing(6);
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: mathBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            math,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      );
      addSpacing(6);
      mathBuffer.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();

      // Math block delimiters
      if (!inMathBlock && line.trim() == r'\[') {
        inMathBlock = true;
        mathBuffer.clear();
        continue;
      }
      if (inMathBlock) {
        if (line.trim() == r'\]') {
          inMathBlock = false;
          flushMath();
        } else {
          if (mathBuffer.isNotEmpty) mathBuffer.writeln();
          mathBuffer.write(line.trim());
        }
        continue;
      }

      // Skip extra empty lines but keep paragraph spacing
      if (line.trim().isEmpty) {
        addSpacing(6);
        continue;
      }

      // Headings
      if (line.startsWith('### ')) {
        addSpacing(6);
        final textLine = line.substring(4).trim();
        children.add(Text(
          _formatMathExpressions(textLine),
          style: TextStyle(
            color: textColor,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ));
        addSpacing(4);
        continue;
      }
      if (line.startsWith('## ')) {
        addSpacing(6);
        final textLine = line.substring(3).trim();
        children.add(Text(
          _formatMathExpressions(textLine),
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ));
        addSpacing(4);
        continue;
      }
      if (line.startsWith('# ')) {
        addSpacing(8);
        final textLine = line.substring(2).trim();
        children.add(Text(
          _formatMathExpressions(textLine),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ));
        addSpacing(4);
        continue;
      }

      // Bullets
      if (line.startsWith('- ') || line.startsWith('* ')) {
        final content = line.substring(2).trim();
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildInlineRichText(_formatMathExpressions(content), textColor)),
          ],
        ));
        continue;
      }

      // Paragraph with inline formatting
      final paragraph = _formatMathExpressions(
        line.replaceAllMapped(RegExp(r'\\boxed\{([^}]+)\}'), (m) => m.group(1)!),
      );
      children.add(_buildInlineRichText(paragraph, textColor));
    }

    // In case block wasn't closed
    if (inMathBlock) {
      flushMath();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Inline formatter: supports **bold** while preserving base style
  Widget _buildInlineRichText(String text, Color textColor) {
    final spans = <TextSpan>[];
    final bold = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;

    for (final m in bold.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, m.start),
          style: TextStyle(color: textColor, fontSize: 16, height: 1.35),
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: TextStyle(color: textColor, fontSize: 16, height: 1.35),
      ));
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: 16, height: 1.35),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  String _formatMathExpressions(String text) {
    String result = text;

    // Replace common LaTeX fractions
    result = result.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (match) => '${match.group(1)}/${match.group(2)}',
    );

    // Replace multiplication symbols
    result = result.replaceAll(r'\times', '×');
    result = result.replaceAll(r'\cdot', '·');

    // Replace division symbols
    result = result.replaceAll(r'\div', '÷');

    // Replace plus/minus
    result = result.replaceAll(r'\pm', '±');
    result = result.replaceAll(r'\mp', '∓');

    // Replace dots and ellipsis
    result = result.replaceAll(r'\dots', '…');
    result = result.replaceAll(r'\ldots', '…');
    result = result.replaceAll(r'\cdots', '⋯');

    // Replace superscripts (simple cases)
    result = result.replaceAllMapped(
      RegExp(r'\^(\d+)'),
      (match) => _superscriptNumber(match.group(1)!),
    );

    // Replace subscripts (simple cases)
    result = result.replaceAllMapped(
      RegExp(r'_(\d+)'),
      (match) => _subscriptNumber(match.group(1)!),
    );

    // Replace square root
    result = result.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]+)\}'),
      (match) => '√${match.group(1)}',
    );
    result = result.replaceAllMapped(
      RegExp(r'\\sqrt\[(\d+)\]\{([^}]+)\}'),
      (match) => '${_superscriptNumber(match.group(1)!)}√${match.group(2)}',
    );

    // Replace infinity
    result = result.replaceAll(r'\infty', '∞');

    // Replace degrees
    result = result.replaceAll(r'\degree', '°');

    // Replace Greek letters (common ones)
    result = result.replaceAll(r'\pi', 'π');
    result = result.replaceAll(r'\alpha', 'α');
    result = result.replaceAll(r'\beta', 'β');
    result = result.replaceAll(r'\gamma', 'γ');
    result = result.replaceAll(r'\delta', 'δ');
    result = result.replaceAll(r'\epsilon', 'ε');
    result = result.replaceAll(r'\theta', 'θ');
    result = result.replaceAll(r'\lambda', 'λ');
    result = result.replaceAll(r'\mu', 'μ');
    result = result.replaceAll(r'\sigma', 'σ');
    result = result.replaceAll(r'\phi', 'φ');
    result = result.replaceAll(r'\omega', 'ω');
    result = result.replaceAll(r'\Delta', 'Δ');
    result = result.replaceAll(r'\Sigma', 'Σ');

    // Replace mathematical operators
    result = result.replaceAll(r'\leq', '≤');
    result = result.replaceAll(r'\geq', '≥');
    result = result.replaceAll(r'\neq', '≠');
    result = result.replaceAll(r'\approx', '≈');
    result = result.replaceAll(r'\equiv', '≡');
    result = result.replaceAll(r'\sim', '∼');
    result = result.replaceAll(r'\simeq', '≃');
    result = result.replaceAll(r'\cong', '≅');
    result = result.replaceAll(r'\propto', '∝');

    // Replace set theory symbols
    result = result.replaceAll(r'\in', '∈');
    result = result.replaceAll(r'\notin', '∉');
    result = result.replaceAll(r'\subset', '⊂');
    result = result.replaceAll(r'\supset', '⊃');
    result = result.replaceAll(r'\cup', '∪');
    result = result.replaceAll(r'\cap', '∩');
    result = result.replaceAll(r'\emptyset', '∅');

    // Replace logic symbols
    result = result.replaceAll(r'\land', '∧');
    result = result.replaceAll(r'\lor', '∨');
    result = result.replaceAll(r'\neg', '¬');
    result = result.replaceAll(r'\implies', '⟹');
    result = result.replaceAll(r'\iff', '⟺');
    result = result.replaceAll(r'\forall', '∀');
    result = result.replaceAll(r'\exists', '∃');

    // Clean up any remaining backslashes for simple commands
    result = result.replaceAll(r'\left(', '(');
    result = result.replaceAll(r'\right)', ')');
    result = result.replaceAll(r'\left[', '[');
    result = result.replaceAll(r'\right]', ']');
    result = result.replaceAll(r'\left\{', '{');
    result = result.replaceAll(r'\right\}', '}');
    result = result.replaceAll(r'\left|', '|');
    result = result.replaceAll(r'\right|', '|');

    // Remove inline math delimiters \( ... \)
    result = result.replaceAll(RegExp(r'\\\(|\\\)'), '');

    // Handle \text{...}
    result = result.replaceAllMapped(RegExp(r'\\text\{([^}]*)\}'), (m) => m.group(1) ?? '');

    // Remove \displaystyle
    result = result.replaceAll(r'\displaystyle', '');

    // Unescape percent and common punctuation
    result = result.replaceAll(r'\%', '%');
    result = result.replaceAll(r'\#', '#');
    result = result.replaceAll(r'\&', '&');
    result = result.replaceAll(r'\_', '_');

    // Remove spacing commands
    result = result.replaceAll(RegExp(r'\\,|\\;|\\:|\\!|\\quad|\\qquad'), '');

    // Superscript/subscript with braces: ^{...}, _{...} (numbers only)
    result = result.replaceAllMapped(RegExp(r'\^\{([0-9]+)\}'), (m) => _superscriptNumber(m.group(1)!));
    result = result.replaceAllMapped(RegExp(r'_\{([0-9]+)\}'), (m) => _subscriptNumber(m.group(1)!));

    // Clean up any remaining double backslashes
    result = result.replaceAll(r'\\', '');

    return result;
  }

  String _superscriptNumber(String number) {
    const superscripts = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'
    };
    return number.split('').map((digit) => superscripts[digit] ?? digit).join();
  }

  String _subscriptNumber(String number) {
    const subscripts = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉'
    };
    return number.split('').map((digit) => subscripts[digit] ?? digit).join();
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
