import json
import re

# Read the fixed SQL file
with open('database/orientation_questions_fixed.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# Function to extract the correct answer text from options
def add_correct_answer(match):
    full_match = match.group(0)
    
    # Extract options JSON array
    options_match = re.search(r"options, correct_answer_index\)\s*VALUES\s*\([^)]+,\s*'([^']+)',\s*'multiple_choice',\s*'(\[[^\]]+\])',\s*(\d+)\)", full_match)
    
    if options_match:
        level_id = options_match.group(1)
        options_json = options_match.group(2)
        correct_index = int(options_match.group(3))
        
        # Parse options
        try:
            options = json.loads(options_json.replace("'", '"'))
            correct_answer = options[correct_index]
            
            # Replace the INSERT statement
            new_insert = full_match.replace(
                'options, correct_answer_index)',
                'options, correct_answer_index, correct_answer)'
            ).replace(
                f'{correct_index}\n);',
                f"{correct_index},\n    '{correct_answer.replace(\"'\", \"''\")}'\n);"
            )
            
            return new_insert
        except:
            pass
    
    return full_match

# Process all INSERT statements for multiple choice questions
pattern = r"INSERT INTO question_bank \(level_id, question_text, question_type, options, correct_answer_index\)[\s\S]*?\);"
content = re.sub(pattern, add_correct_answer, content)

# For match_following questions, they already have correct_answer as 'See match_pairs', so no change needed

# Write the final version
with open('database/orientation_questions_final.sql', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Created orientation_questions_final.sql with correct_answer field added!")
