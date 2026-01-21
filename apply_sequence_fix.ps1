# PowerShell script to insert sequence builder save logic
$filePath = "d:\Projects\entre-nous\lib\screens\admin\add_question_screen.dart"
$content = Get-Content $filePath -Raw

$insertCode = @"
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

# Find and replace
$pattern = "     } else if \(`$_questionType == 'scenario_decision'\) {"
$replacement = $insertCode + "`r`n" + $pattern

$newContent = $content -replace [regex]::Escape($pattern), $replacement

# Write back
$newContent | Set-Content $filePath -NoNewline

Write-Host "✅ Successfully added sequence_builder save logic!" -ForegroundColor Green
Write-Host "The code was inserted before the scenario_decision block."
