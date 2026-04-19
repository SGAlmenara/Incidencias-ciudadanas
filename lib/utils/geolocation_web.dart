import 'package:geolocator/geolocator.dart';

Future<Map<String, double>> obtenerPosicionWeb() async {
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return {'lat': position.latitude, 'lng': position.longitude};
}
