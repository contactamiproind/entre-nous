import sys

# Fix indentation in add_question_screen.dart
file_path = r"d:\Projects\entre-nous\lib\screens\admin\add_question_screen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Add 4 spaces to lines 653-1026 (0-indexed: 652-1025)
for i in range(652, min(1026, len(lines))):
    if lines[i].strip():  # Only indent non-empty lines
        lines[i] = '    ' + lines[i]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Indentation fixed successfully!")
print(f"Added 4 spaces to lines 653-1026")
