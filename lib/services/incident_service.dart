import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';

class IncidentService {
  final supabase = Supabase.instance.client;

  Future<Incident> createIncident(
    String titulo,
    String descripcion,
    double lat,
    double lng,
    String? direccion,
    List<String> imagenes,
  ) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('incidencias')
          .insert({
            'titulo': titulo,
            'descripcion': descripcion,
            'latitud': lat,
            'longitud': lng,
            'direccion': direccion,
            'img_url': imagenes,
            'estado': 'pendiente',
            'user_id': userId,
            'fecha': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Incident.fromMap(response);
    } catch (e) {
      print("Error en createIncident: $e");
      throw Exception("No se pudo crear la incidencia");
    }
  }

  // OBTENER INCIDENCIA POR ID
  Future<Incident?> getIncidentById(String id) async {
    try {
      final data = await supabase
          .from('incidencias')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Incident.fromMap(data);
    } catch (e) {
      print("Error en getIncidentById: $e");
      return null;
    }
  }

  // OBTENER TODAS LAS INCIDENCIAS DE UN USUARIO
  Future<List<Incident>> getIncidentsByUser(String userId) async {
    try {
      final data = await supabase
          .from('incidencias')
          .select('*')
          .eq('user_id', userId)
          .order('fecha', ascending: false);

      return (data as List).map((e) => Incident.fromMap(e)).toList();
    } catch (e) {
      print("Error en getIncidentsByUser: $e");
      return [];
    }
  }

  // OBTENER INCIDENCIAS POR ESTADO (admin)
  Future<List<Incident>> getIncidentsByEstado(String estado) async {
    try {
      final data = await supabase
          .from('incidencias')
          .select('*')
          .eq('estado', estado)
          .order('fecha', ascending: false);

      return (data as List).map((e) => Incident.fromMap(e)).toList();
    } catch (e) {
      print("❌ Error en getIncidentsByEstado: $e");
      return [];
    }
  }

  // ACTUALIZAR INCIDENCIA — devuelve el objeto actualizado
  Future<Incident> updateIncident({
    required String id,
    required String titulo,
    required String descripcion,
    required String estado,
    required double lat,
    required double lng,
    required String direccion,
    required List<String> imagenes,
  }) async {
    try {
      final response = await supabase
          .from('incidencias')
          .update({
            'titulo': titulo,
            'descripcion': descripcion,
            'estado': estado,
            'latitud': lat,
            'longitud': lng,
            'direccion': direccion,
            'img_url': imagenes,
          })
          .eq('id', id)
          .select()
          .single();

      return Incident.fromMap(response);
    } catch (e) {
      print("Error en updateIncident: $e");
      throw Exception("No se pudo actualizar la incidencia");
    }
  }

  // ELIMINAR INCIDENCIA
  Future<bool> deleteIncident(String id) async {
    try {
      await supabase.from('incidencias').delete().eq('id', id);
      return true;
    } catch (e) {
      print("Error en deleteIncident: $e");
      return false;
    }
  }
}
