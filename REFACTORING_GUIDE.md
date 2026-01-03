# Production Refactoring Guide

## ⚠️ IMPORTANT: Backup First
```bash
git add .
git commit -m "Before refactoring - working state"
```

---

## Phase 1: Create Folder Structure

```bash
cd /Users/amitshanker/CascadeProjects/entre-nous/lib/screens

# Create new folders
mkdir -p admin
mkdir -p user
mkdir -p common
```

---

## Phase 2: Move Files

### Admin Screens
```bash
mv enhanced_admin_dashboard.dart admin/
mv user_management_screen.dart admin/
mv user_profile_detail_screen.dart admin/
mv department_management_screen.dart admin/
mv question_bank_management_screen.dart admin/
mv add_question_screen.dart admin/
```

### User Screens
```bash
mv enhanced_user_dashboard.dart user/
mv my_departments_screen.dart user/
mv pathway_detail_screen.dart user/
mv quiz_screen.dart user/
mv profile_actions_screen.dart user/
```

### Common Screens
```bash
mv login_screen.dart common/
mv signup_screen.dart common/
mv splash_screen.dart common/
mv welcome_screen.dart common/
```

### Delete Redundant Screens
```bash
rm no_pathways_screen.dart
rm pathway_selection_screen.dart
```

---

## Phase 3: Update Imports

### Files to Update (in order):

#### 1. main.dart
```dart
// OLD imports
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/enhanced_admin_dashboard.dart';
import 'screens/enhanced_user_dashboard.dart';

// NEW imports
import 'screens/common/login_screen.dart';
import 'screens/common/signup_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/welcome_screen.dart';
import 'screens/admin/enhanced_admin_dashboard.dart';
import 'screens/user/enhanced_user_dashboard.dart';
```

#### 2. Admin Screens
Update imports in:
- `admin/enhanced_admin_dashboard.dart`
- `admin/user_management_screen.dart`
- `admin/user_profile_detail_screen.dart`
- `admin/department_management_screen.dart`
- `admin/question_bank_management_screen.dart`
- `admin/add_question_screen.dart`

Change:
```dart
// OLD
import 'user_management_screen.dart';
import '../widgets/assign_pathways_tab.dart';

// NEW
import 'user_management_screen.dart'; // Same folder, no change
import '../../widgets/assign_pathways_tab.dart'; // Go up 2 levels
```

#### 3. User Screens
Update imports in:
- `user/enhanced_user_dashboard.dart`
- `user/my_departments_screen.dart`
- `user/pathway_detail_screen.dart`
- `user/quiz_screen.dart`
- `user/profile_actions_screen.dart`

Change:
```dart
// OLD
import 'pathway_detail_screen.dart';
import '../services/pathway_service.dart';

// NEW
import 'pathway_detail_screen.dart'; // Same folder, no change
import '../../services/pathway_service.dart'; // Go up 2 levels
```

#### 4. Common Screens
Update imports in:
- `common/login_screen.dart`
- `common/signup_screen.dart`
- `common/splash_screen.dart`

Change:
```dart
// OLD
import '../utils/responsive_utils.dart';

// NEW
import '../../utils/responsive_utils.dart'; // Go up 2 levels
```

---

## Phase 4: Remove Redundant Code

### Files with unused fields (remove these):

#### add_question_screen.dart
```dart
// REMOVE line 30
final _selectedSubcategory = null; // Unused
```

#### quiz_screen.dart
```dart
// REMOVE lines 33, 40
bool _isSubmitting = false; // Unused
bool _showLevelIntro = true; // Unused

// REMOVE lines 894-920 (unused methods)
List<Color> _getGradientColors(String difficulty) { ... }
Color _getPrimaryColor(String difficulty) { ... }
```

#### enhanced_admin_dashboard.dart
```dart
// REMOVE line 22
bool _isLoading = true; // Unused (using _isLoading from state but not reading it)

// REMOVE lines 91-105 (unused method)
void _showAssignPathwayDialog() { ... }

// REMOVE lines 369+ (unused method)
Widget _buildDepartmentTab() { ... }
```

#### my_departments_screen.dart
```dart
// REMOVE line 15
List<Map<String, dynamic>> _availableDepartments = []; // Unused
```

#### enhanced_user_dashboard.dart
```dart
// REMOVE lines 1047+ (unused method)
void _showOrientationRequiredDialog() { ... }
```

---

## Phase 5: UI Improvements (No color/font changes)

### Global Theme Enhancements (lib/main.dart)

Add to MaterialApp theme:
```dart
theme: ThemeData(
  // Existing colors...
  
  // Enhanced card theme
  cardTheme: CardTheme(
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  // Enhanced button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  ),
),
```

### Screen-Specific Improvements

#### 1. Login/Signup Screens
- Add subtle shadow to logo container (already done)
- Increase card elevation from 0 to 2
- Add shadow to buttons

#### 2. Dashboard Cards
- Consistent elevation: 2 for normal, 4 for current/selected
- Border radius: 16px consistently
- Shadow color: `Colors.black.withOpacity(0.1)`

#### 3. List Items
- Add subtle dividers between items
- Consistent padding: 16px
- Hover effect on cards (for web)

#### 4. Bottom Navigation
- Add subtle top border
- Increase icon size slightly for better touch targets

---

## Phase 6: Test Checklist

### Admin Flow
- [ ] Login as admin
- [ ] Dashboard loads without errors
- [ ] Navigate to User Management
- [ ] Navigate to Department Management
- [ ] Navigate to Question Bank
- [ ] Assign department to user
- [ ] Logout

### User Flow
- [ ] Login as user
- [ ] Dashboard loads without errors
- [ ] See assigned departments
- [ ] Click on department
- [ ] See levels
- [ ] Click on level
- [ ] See questions
- [ ] Answer question
- [ ] Logout

### Common
- [ ] Splash screen works
- [ ] Welcome screen works
- [ ] Login screen works
- [ ] Signup screen works
- [ ] Enter key login works

---

## Phase 7: Final Cleanup

```bash
# Remove backup files if any
find . -name "*.dart~" -delete

# Format all Dart files
dart format lib/

# Analyze for issues
flutter analyze

# Run the app
flutter run
```

---

## Rollback Plan

If something breaks:
```bash
git reset --hard HEAD
git clean -fd
```

---

## Estimated Time
- Phase 1-2: 5 minutes (file moves)
- Phase 3: 30 minutes (import updates)
- Phase 4: 15 minutes (remove redundant code)
- Phase 5: 20 minutes (UI improvements)
- Phase 6: 30 minutes (testing)
- **Total: ~2 hours**

---

## Notes
- Do this refactoring in a separate branch
- Test thoroughly before merging to main
- Update any documentation/README
- Consider creating a PR for review

---

## Quick Command Summary

```bash
# Create folders
mkdir -p lib/screens/{admin,user,common}

# Move admin files
mv lib/screens/{enhanced_admin_dashboard,user_management_screen,user_profile_detail_screen,department_management_screen,question_bank_management_screen,add_question_screen}.dart lib/screens/admin/

# Move user files
mv lib/screens/{enhanced_user_dashboard,my_departments_screen,pathway_detail_screen,quiz_screen,profile_actions_screen}.dart lib/screens/user/

# Move common files
mv lib/screens/{login_screen,signup_screen,splash_screen,welcome_screen}.dart lib/screens/common/

# Delete redundant
rm lib/screens/{no_pathways_screen,pathway_selection_screen}.dart

# Then manually update imports in each file
```

---

**This is a comprehensive refactoring. Take your time and test thoroughly at each phase!**
