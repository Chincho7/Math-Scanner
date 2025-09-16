import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorHistory {
  final String question;
  final String answer;
  final String? calculation;
  final DateTime timestamp;

  CalculatorHistory({
    required this.question,
    required this.answer,
    this.calculation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'calculation': calculation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculatorHistory.fromJson(Map<String, dynamic> json) {
    return CalculatorHistory(
      question: json['question'],
      answer: json['answer'],
      calculation: json['calculation'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CalculatorHistoryService {
  static const String _historyKey = 'calculator_history';
  static const int _maxHistoryItems = 100;

  Future<void> saveCalculation({
    required String question,
    required String answer,
    String? calculation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await getHistory();
      
      final newItem = CalculatorHistory(
        question: question,
        answer: answer,
        calculation: calculation,
        timestamp: DateTime.now(),
      );
      
      // Add to beginning of list
      historyList.insert(0, newItem);
      
      // Keep only the most recent items
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }
      
      final jsonList = historyList.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving calculation history: $e');
    }
  }

  Future<List<CalculatorHistory>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(historyJson);
      return jsonList.map((json) => CalculatorHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error loading calculation history: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing calculation history: $e');
    }
  }

  Future<List<CalculatorHistory>> searchHistory(String query) async {
    final history = await getHistory();
    final lowercaseQuery = query.toLowerCase();
    
    return history.where((item) {
      return item.question.toLowerCase().contains(lowercaseQuery) ||
             item.answer.toLowerCase().contains(lowercaseQuery) ||
             (item.calculation?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
}
