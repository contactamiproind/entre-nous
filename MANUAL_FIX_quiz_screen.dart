// MANUAL FIX: Replace these two methods in quiz_screen.dart
// Location: Around line 1259-1298

// Method 1: _isFlipCardGame (replace lines 1259-1270)
bool _isFlipCardGame(Map<String, dynamic> question) {
  // Check if options contains pairs array with 'question' and 'answer' keys
  final options = question['options'];
  if (options == null || options is! List || options.isEmpty) return false;
  
  // Check if first item has the pair structure {id, question, answer}
  if (options[0] is Map) {
    final firstItem = options[0] as Map;
    return firstItem.containsKey('question') && firstItem.containsKey('answer');
  }
  
  return false;
}

// Method 2: _buildCardPairs (replace lines 1273-1298)
List<Map<String, dynamic>> _buildCardPairs(Map<String, dynamic> question) {
  final options = question['options'];
  if (options == null || options is! List) return [];
  
  // Options already contains pairs in the format: [{id, question, answer}, ...]
  return List<Map<String, dynamic>>.from(options);
}
