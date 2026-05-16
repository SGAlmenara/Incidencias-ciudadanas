import 'package:geolocator/geolocator.dart';

// Obtiene coordenadas actuales en web usando Geolocator.
Future<Map<String, double>> obtenerPosicionWeb() async {
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return {'lat': position.latitude, 'lng': position.longitude};
}
