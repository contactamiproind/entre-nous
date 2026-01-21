import re

# Read the file
file_path = r"d:\Projects\entre-nous\lib\screens\admin\add_question_screen.dart"
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# The code to insert
insert_code = """     } else if (_questionType == 'sequence_builder') {
       // Prepare sequence builder data
       final sentences = [];
       for (int i = 0; i < _sequenceSentences.length; i++) {
         final text = _sequenceSentences[i]['controller']!.text.trim();
         if (text.isNotEmpty) {
           sentences.add({
             'id': i + 1,
             'text': text,
             'correct_position': i + 1,
           });
         }
       }
       
       if (sentences.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Please add at least one sentence'),
             backgroundColor: Colors.red,
           ),
         );
         setState(() => _isSaving = false);
         return;
       }
       
       questionData['options'] = sentences;
       debugPrint('📤 Sequence Builder sentences: $sentences');
"""

# Find the line with scenario_decision and insert before it
pattern = r"(\s+}\s+else if \(_questionType == 'scenario_decision'\) \{)"
replacement = insert_code + r"\1"

new_content = re.sub(pattern, replacement, content, count=1)

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("✅ Successfully added sequence_builder save logic!")
print("The code was inserted before the scenario_decision block.")
