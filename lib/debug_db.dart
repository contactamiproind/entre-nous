import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

Future<void> inspectDatabase() async {
  try {
    final response = await Supabase.instance.client
        .from('user_pathway')
        .select('*, pathways(name)');
    
    print('--- USER PATHWAY ENTRIES ---');
    for (var row in response) {
      print('User: ${row['user_id']} | Pathway: ${row['pathways']['name']} | IsCurrent: ${row['is_current']} | ID: ${row['id']}');
    }
    print('----------------------------');
  } catch (e) {
    print('Error inspecting DB: $e');
  }
}
