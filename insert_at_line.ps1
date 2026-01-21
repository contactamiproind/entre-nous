# Read file
$file = "d:\Projects\entre-nous\lib\screens\admin\add_question_screen.dart"
$lines = Get-Content $file

# Find the line number with scenario_decision
$lineNum = 0
for ($i = 0; $i < $lines.Count; $i++) {
    if ($lines[$i] -match "scenario_decision") {
        $lineNum = $i
        break
    }
}

Write-Host "Found scenario_decision at line: $lineNum"
Write-Host "Line content: $($lines[$lineNum])"

# Insert new lines before this line
$newCode = @"
     } else if (_questionType == 'sequence_builder') {
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
       debugPrint('📤 Sequence Builder sentences: `$sentences');
"@

# Split new code into lines
$newLines = $newCode -split "`n"

# Create new array with inserted lines
$result = @()
$result += $lines[0..($lineNum - 1)]
$result += $newLines
$result += $lines[$lineNum..($lines.Count - 1)]

# Write back
$result | Set-Content $file

Write-Host "✅ Successfully inserted sequence_builder save logic!" -ForegroundColor Green
