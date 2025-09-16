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
  bool _showHistory = false;
  
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
      // Check if it's a simple math expression
      String response;
      String? calculation;
      
      if (_isSimpleMathExpression(userMessage)) {
        // Handle simple math expressions
        print('Processing simple math: $userMessage');
        calculation = _mathSolver.solveMathProblem(userMessage);
        print('Math solver result: $calculation');
        
        if (calculation.isNotEmpty && !calculation.contains('Error')) {
          response = "The answer is **$calculation**.\n\nHere's how I calculated it:\n$userMessage = $calculation";
        } else {
          response = "I had trouble calculating that. Let me try a different approach.";
          calculation = null;
        }
      } else {
        // Use OpenAI for more complex queries
        try {
          print('Sending to OpenAI: $userMessage');
          response = await _openAIService.solveMathProblem(userMessage);
          print('OpenAI response: $response');
          
          // Try to extract any calculations from the response
          final calcMatch = RegExp(r'(?:=\s*|answer[:\s]*is[:\s]*|result[:\s]*is[:\s]*|equals[:\s]*)?(-?\d+(?:\.\d+)?)', caseSensitive: false).allMatches(response);
          if (calcMatch.isNotEmpty) {
            calculation = calcMatch.last.group(1);
            print('Extracted calculation: $calculation');
          }
        } catch (e) {
          print('OpenAI error: $e');
          response = "I'm having trouble connecting to my advanced reasoning. Let me try with basic math functions.";
          if (_containsMathSymbols(userMessage)) {
            calculation = _mathSolver.solveMathProblem(userMessage);
            if (calculation.isNotEmpty && !calculation.contains('Error')) {
              response = "Using basic calculation: $userMessage = **$calculation**";
            }
          }
        }
      }
      
      setState(() {
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          calculation: calculation,
        ));
        _isLoading = false;
      });
      
      // Save successful calculations to history
      if (calculation != null && calculation.isNotEmpty && !calculation.contains('Error')) {
        await _historyService.saveCalculation(
          question: userMessage,
          answer: response,
          calculation: calculation,
        );
      }
    } catch (e) {
      print('General error in _sendMessage: $e');
      setState(() {
        _messages.add(ChatMessage(
          content: "I encountered an error while processing your request. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }
  
  bool _isSimpleMathExpression(String text) {
    // Check if the text looks like a simple math expression
    return RegExp(r'^[\d\s\+\-\*\/\×\÷\(\)\.]+$').hasMatch(text) && 
           _containsMathSymbols(text);
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
    // Handle bold formatting (**text**)
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    
    for (final match in regex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: textColor, fontSize: 16),
        ));
      }
      
      // Add the bold part
      parts.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: textColor, fontSize: 16),
      ));
    }
    
    // If no formatting found, return simple text
    if (parts.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: 16),
      );
    }
    
    return RichText(
      text: TextSpan(children: parts),
    );
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
