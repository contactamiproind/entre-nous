
import os

file_path = r"D:\Projects\entre-nous\lib\screens\end_game\end_game_screen.dart"

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
found = False
skip = 0

for i, line in enumerate(lines):
    if skip > 0:
        skip -= 1
        continue
        
    if "..._placedObjects.map" in line:
        # We found the map line. 
        # Structure we want to inject after this line:
        #   ],
        #  ),
        # );
        # }
        # );
        # }
        # );
        # },
        # ),
        # ); 
        # }
        # ),
        
        # Current bad structure (approx lines 640-653):
        # ...map...
        # ],
        # ),
        # );
        # }
        # );
        # }
        # );
        # },
        # ),
        # ),  <-- Bad
        # );  <-- Bad
        # }
        # ),
        
        # We want to replace everything from here until the next "child: Center" or end of Stack?
        # Actually simplest is to rewrite the closing sequence.
        
        # Keep the line with map
        new_lines.append(line)
        
        # Next lines should be closing stack/container/etc.
        # list close
        new_lines.append(lines[i+1]) # ],
        # stack close
        new_lines.append(lines[i+2]) # ),
        # container close
        new_lines.append(lines[i+3]) # );
        # DragTarget builder close
        new_lines.append(lines[i+4]) # }
        # DragTarget widget close
        new_lines.append(lines[i+5]) # );
        # LayoutBuilder builder close
        new_lines.append(lines[i+6]) # }
        # LayoutBuilder widget close
        new_lines.append(lines[i+7]) # );
        # DragTarget (outer) builder close
        new_lines.append(lines[i+8]) # },
        # DragTarget (outer) widget close
        new_lines.append(lines[i+9]) # ),
        
        # NOW THE FIX
        # We want to replace lines i+10 and i+11 with just );
        # previous i+10 was ),
        # previous i+11 was );
        
        indent = lines[i+9].replace(lines[i+9].strip(), "")
        # Use slightly less indent for the closing SizedBox );
        # Actually line 650 (i+10) had 36 spaces?
        # line 649 (i+9) had 32 spaces.
        # We want ); at 32 spaces?
        
        new_lines.append(indent + ");\n")
        
        # Skip the next 2 lines (original 650, 651)
        # Check if they look like the bad ones?
        # Original 650: "                                    ),"
        # Original 651: "                                  );"
        
        skip = 2 
        
        found = True
    else:
        new_lines.append(line)

if found:
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    print("Fixed syntax error.")
else:
    print("Could not find target line.")
