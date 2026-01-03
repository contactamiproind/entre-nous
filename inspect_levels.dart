import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/supabase_config.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final supabase = Supabase.instance.client;

  print('--- Pathways ---');
  final pathways = await supabase.from('pathways').select();
  for (var p in pathways) {
    print('${p['id']} - ${p['name']}');
  }

  print('\n--- Pathway Levels ---');
  final levels = await supabase.from('pathway_levels').select();
  if (levels.isEmpty) {
    print('NO LEVELS FOUND');
  } else {
    for (var l in levels) {
      print('Pathway: ${l['pathway_id']} | Level: ${l['level_number']} - ${l['level_name']}');
    }
  }
}
