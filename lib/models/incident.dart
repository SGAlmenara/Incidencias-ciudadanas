class Incident {
  final String id;
  final String? titulo;
  final String? descripcion;
  final List<String> imgUrls; // lista de imágenes base64
  final double? latitud;
  final double? longitud;
  final String? direccion;
  final String estado;
  final DateTime fecha;
  final String userId;

  Incident({
    required this.id,
    required this.fecha,
    required this.userId,
    required this.estado,
    required this.imgUrls,
    this.titulo,
    this.descripcion,
    this.latitud,
    this.longitud,
    this.direccion,
  });

  // FACTORY: convertir desde Supabase
  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'].toString(),
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      imgUrls: List<String>.from(map['img_url'] ?? []),
      latitud: map['latitud']?.toDouble(),
      longitud: map['longitud']?.toDouble(),
      direccion: map['direccion'],
      estado: map['estado'],
      fecha: DateTime.parse(map['fecha']),
      userId: map['user_id'],
    );
  }

  // Convertir a mapa para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'img_url': imgUrls,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
      'user_id': userId,
    };
  }

  // HELPERS

  /// ¿Tiene imágenes?
  bool get hasImages => imgUrls.isNotEmpty;

  /// Primera imagen (o null)
  String? get firstImage => hasImages ? imgUrls.first : null;

  /// Fecha corta para listas
  String get shortDate =>
      "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";

  /// Copiar el objeto cambiando solo algunos campos
  Incident copyWith({
    String? titulo,
    String? descripcion,
    List<String>? imgUrls,
    double? latitud,
    double? longitud,
    String? direccion,
    String? estado,
  }) {
    return Incident(
      id: id,
      fecha: fecha,
      userId: userId,
      estado: estado ?? this.estado,
      imgUrls: imgUrls ?? this.imgUrls,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccion: direccion ?? this.direccion,
    );
  }
}
