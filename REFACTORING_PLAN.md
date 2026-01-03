# App Refactoring Plan

## Screen Organization

### Admin Screens (lib/screens/admin/)
- enhanced_admin_dashboard.dart
- user_management_screen.dart
- user_profile_detail_screen.dart
- department_management_screen.dart
- question_bank_management_screen.dart
- add_question_screen.dart

### User Screens (lib/screens/user/)
- enhanced_user_dashboard.dart
- my_departments_screen.dart
- pathway_detail_screen.dart
- quiz_screen.dart
- profile_actions_screen.dart

### Shared/Common Screens (lib/screens/common/)
- login_screen.dart
- signup_screen.dart
- splash_screen.dart
- welcome_screen.dart

### Redundant Screens to Remove
- no_pathways_screen.dart (functionality merged into my_departments_screen.dart)
- pathway_selection_screen.dart (not used in new schema)

## UI Improvements (No color/font changes)
1. Consistent card elevation and shadows
2. Improved spacing and padding
3. Better border radius consistency
4. Enhanced button styling (shadows, elevation)
5. Consistent container decorations
6. Better visual hierarchy with shadows

## Import Updates Required
- All files importing screens will need path updates
- main.dart route definitions
- Navigation calls throughout the app
