import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Incident>> getIncidents() async {
    final data = await supabase.from('incidencias').select();

    return data.map<Incident>((item) => Incident.fromMap(item)).toList();
  }
}
