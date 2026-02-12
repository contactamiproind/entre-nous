import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> inspectDatabase() async {
  try {
    final response = await Supabase.instance.client
        .from('usr_dept')
        .select('*, departments(title)');
    
    print('--- USER DEPARTMENT ENTRIES ---');
    for (var row in response) {
      print('User: ${row['user_id']} | Department: ${row['departments']?['title']} | IsCurrent: ${row['is_current']} | ID: ${row['id']}');
    }
    print('------------------------------');
  } catch (e) {
    print('Error inspecting DB: $e');
  }
}
