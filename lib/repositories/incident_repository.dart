//testeo - mockear el repository sin tocar Supabase
//cambiar Supabase por Firebase, solo cambiar el Service

import '../models/incident.dart';
import '../services/incident_service.dart';

class IncidentRepository {
  final IncidentService _service;

  IncidentRepository({IncidentService? service})
    : _service = service ?? IncidentService();

  // CREAR INCIDENCIA — devuelve el objeto creado
  Future<Incident> createIncident({
    required String titulo,
    required String descripcion,
    required double lat,
    required double lng,
    required String direccion,
    required String sector,
    required List<String> imagenes,
  }) async {
    return await _service.createIncident(
      titulo,
      descripcion,
      lat,
      lng,
      direccion,
      sector,
      imagenes,
    );
  }

  // OBTENER INCIDENCIA POR ID
  Future<Incident?> getIncidentById(String id) async {
    return await _service.getIncidentById(id);
  }

  // OBTENER TODAS LAS INCIDENCIAS DE UN USUARIO
  Future<List<Incident>> getIncidentsByUser(String userId) async {
    return await _service.getIncidentsByUser(userId);
  }

  // OBTENER INCIDENCIAS POR ESTADO (admin)
  Future<List<Incident>> getIncidentsByEstado(String estado) async {
    return await _service.getIncidentsByEstado(estado);
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
    return await _service.updateIncident(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      estado: estado,
      lat: lat,
      lng: lng,
      direccion: direccion,
      sector: sector,
      imagenes: imagenes,
    );
  }

  // ELIMINAR INCIDENCIA
  Future<bool> deleteIncident(String id) async {
    return await _service.deleteIncident(id);
  }
}
