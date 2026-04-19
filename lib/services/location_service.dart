import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, double>> obtenerPosicion() async {
    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permiso de ubicación denegado permanentemente';
    }

    // Obtener posición
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {'lat': position.latitude, 'lng': position.longitude};
  }
}
