class IncidentComment {
  final String id;
  final String incidentId;
  final String authorId;
  final String message;
  final DateTime createdAt;
  final String authorName;
  final String authorRole;

  IncidentComment({
    required this.id,
    required this.incidentId,
    required this.authorId,
    required this.message,
    required this.createdAt,
    required this.authorName,
    required this.authorRole,
  });

  factory IncidentComment.fromMap(
    Map<String, dynamic> map, {
    String? authorName,
    String? authorRole,
  }) {
    return IncidentComment(
      id: map['id'].toString(),
      incidentId: map['incidencia_id'].toString(),
      authorId: map['autor_id'].toString(),
      message: (map['mensaje'] ?? '').toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      authorName: (authorName == null || authorName.trim().isEmpty)
          ? 'Usuario'
          : authorName,
      authorRole: (authorRole == null || authorRole.trim().isEmpty)
          ? 'user'
          : authorRole,
    );
  }
}
