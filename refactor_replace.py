import os
import re

# Define replacements
replacements = [
    ('pathway_selection_screen', 'department_selection_screen'),
    ('pathway_detail_screen', 'department_detail_screen'),
    ('my_pathways_screen', 'my_departments_screen'),
    ('no_pathways_screen', 'no_departments_screen'),
    ('PathwaySelectionScreen', 'DepartmentSelectionScreen'),
    ('PathwayDetailScreen', 'DepartmentDetailScreen'),
    ('MyPathwaysScreen', 'MyDepartmentsScreen'),
    ('NoPathwaysScreen', 'NoDepartmentsScreen'),
    ('_PathwayCard', '_DepartmentCard'),
    ('_loadPathways', '_loadDepartments'),
    ('_enrollInPathway', '_enrollInDepartment'),
    ('_getPathwayIcon', '_getDepartmentIcon'),
    ('_getPathwayColor', '_getDepartmentColor'),
    ('_loadPathwayData', '_loadDepartmentData'),
    ('_switchToPathway', '_switchToDepartment'),
    ('_enrolledPathways', '_enrolledDepartments'),
    ('_availablePathways', '_availableDepartments'),
    ('"Pathway"', '"Department"'),
    ('"Pathways"', '"Departments"'),
    ('"My Pathways"', '"My Departments"'),
    ('"Select a Pathway"', '"Select a Department"'),
    ("'Pathway'", "'Department'"),
    ("'Pathways'", "'Departments'"),
    ("'My Pathways'", "'My Departments'"),
    ("tooltip: 'My Pathways'", "tooltip: 'My Departments'"),
]

# Process all .dart files in lib/screens
screens_dir = r'c:\Users\naika\.gemini\antigravity\scratch\quiz_app\lib\screens'

for filename in os.listdir(screens_dir):
    if filename.endswith('.dart'):
        filepath = os.path.join(screens_dir, filename)
        print(f'Processing {filename}...')
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Apply all replacements
        for old, new in replacements:
            content = content.replace(old, new)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f'  ✓ Updated {filename}')

print('\n✅ All replacements complete!')
