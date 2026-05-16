import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';
import '../models/incident_comment.dart';

class IncidentService {
  final supabase = Supabase.instance.client;

  Future<Map<String, int>> getCommentCountByIncidentIds(
    List<String> incidentIds,
  ) async {
    if (incidentIds.isEmpty) return {};

    try {
      final data = await supabase
          .from('incidencia_comentarios')
          .select('incidencia_id')
          .inFilter('incidencia_id', incidentIds);

      final rows = (data as List).cast<Map<String, dynamic>>();
      final counts = <String, int>{};

      for (final row in rows) {
        final incidentId = row['incidencia_id']?.toString() ?? '';
        if (incidentId.isEmpty) continue;
        counts[incidentId] = (counts[incidentId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error en getCommentCountByIncidentIds: $e');
      return {};
    }
  }

  Future<Map<String, String>> getLatestCommentPreviewByIncidentIds(
    List<String> incidentIds,
  ) async {
    if (incidentIds.isEmpty) return {};

    try {
      final data = await supabase
          .from('incidencia_comentarios')
          .select('incidencia_id, mensaje, created_at')
          .inFilter('incidencia_id', incidentIds)
          .order('created_at', ascending: false);

      final rows = (data as List).cast<Map<String, dynamic>>();
      final previews = <String, String>{};

      for (final row in rows) {
        final incidentId = row['incidencia_id']?.toString() ?? '';
        if (incidentId.isEmpty || previews.containsKey(incidentId)) {
          continue;
        }

        final message = (row['mensaje'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          previews[incidentId] = message;
        }
      }

      return previews;
    } catch (e) {
      print('Error en getLatestCommentPreviewByIncidentIds: $e');
      return {};
    }
  }

  Future<List<IncidentComment>> getIncidentComments(String incidentId) async {
    try {
      final data = await supabase
          .from('incidencia_comentarios')
          .select('id, incidencia_id, autor_id, mensaje, created_at')
          .eq('incidencia_id', incidentId)
          .order('created_at', ascending: true);

      final rows = (data as List).cast<Map<String, dynamic>>();
      final authorIds = rows
          .map((row) => row['autor_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> profileById = {};
      if (authorIds.isNotEmpty) {
        final profileData = await supabase
            .from('profiles')
            .select('id, nombre, apellidos, email, role')
            .inFilter('id', authorIds);

        for (final item in (profileData as List).cast<Map<String, dynamic>>()) {
          profileById[item['id'].toString()] = item;
        }
      }

      return rows.map((row) {
        final authorId = row['autor_id']?.toString() ?? '';
        final profile = profileById[authorId];
        final nombre = (profile?['nombre'] ?? '').toString().trim();
        final apellidos = (profile?['apellidos'] ?? '').toString().trim();
        final email = (profile?['email'] ?? '').toString().trim();
        final role = (profile?['role'] ?? 'user').toString();
        final normalizedRole = role.trim().toLowerCase();
        final fullName = [
          nombre,
          apellidos,
        ].where((part) => part.isNotEmpty).join(' ').trim();
        final displayName = normalizedRole == 'admin'
            ? 'Admin'
            : (fullName.isNotEmpty
                  ? fullName
                  : (email.isNotEmpty ? email : 'Usuario'));

        return IncidentComment.fromMap(
          row,
          authorName: displayName,
          authorRole: normalizedRole,
        );
      }).toList();
    } catch (e) {
      print('Error en getIncidentComments: $e');
      return [];
    }
  }

  Future<void> addIncidentComment({
    required String incidentId,
    required String message,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final cleanMessage = message.trim();
      if (cleanMessage.isEmpty) {
        throw Exception('El comentario no puede estar vacío');
      }

      await supabase.from('incidencia_comentarios').insert({
        'incidencia_id': incidentId,
        'autor_id': userId,
        'mensaje': cleanMessage,
      });
    } catch (e) {
      print('Error en addIncidentComment: $e');
      rethrow;
    }
  }

  Future<Incident> createIncident(
    String titulo,
    String descripcion,
    double lat,
    double lng,
    String? direccion,
    String sector,
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
            'sector': sector,
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
    required String sector,
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
            'sector': sector,
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

  Future<void> updateIncidentStatus({
    required String id,
    required String estado,
  }) async {
    try {
      await supabase
          .from('incidencias')
          .update({'estado': estado})
          .eq('id', id);
    } catch (e) {
      print("Error en updateIncidentStatus: $e");
      throw Exception("No se pudo actualizar el estado");
    }
  }

  // ELIMINAR INCIDENCIA
  Future<bool> deleteIncident(String id) async {
    try {
      final deleted = await supabase
          .from('incidencias')
          .delete()
          .eq('id', id)
          .select('id');

      return (deleted as List).isNotEmpty;
    } catch (e) {
      print("Error en deleteIncident: $e");
      return false;
    }
  }
}
