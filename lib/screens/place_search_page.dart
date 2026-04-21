import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

// PÁGINA PARA BUSCAR DIRECCIÓN CON GOOGLE PLACES, DEVOLVIENDO DIRECCIÓN Y COORDENADAS A LA PÁGINA ANTERIOR
class PlaceSearchPage extends StatefulWidget {
  final String apiKey;

  const PlaceSearchPage({super.key, required this.apiKey});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  late FlutterGooglePlacesSdk places;
  List<AutocompletePrediction> sugerencias = [];

  @override
  void initState() {
    super.initState();
    places = FlutterGooglePlacesSdk(widget.apiKey);
  }

  // Método para buscar direcciones a medida que el usuario escribe,
  //utilizando el servicio de Google Places para obtener sugerencias de autocompletado.
  //Si la consulta es menor a 3 caracteres, se limpian las sugerencias.
  Future<void> buscar(String query) async {
    if (query.length < 3) {
      setState(() => sugerencias = []);
      return;
    }

    final result = await places.findAutocompletePredictions(query);
    setState(() => sugerencias = result.predictions);
  }

  // Método para seleccionar una dirección de las sugerencias,
  //obteniendo su ubicación y dirección completa, y devolviendo esta información a la página anterior.
  Future<void> seleccionar(AutocompletePrediction p) async {
    final details = await places.fetchPlace(
      p.placeId,
      fields: [PlaceField.Location, PlaceField.Address],
    );

    final loc = details.place!.latLng!;
    final direccion = details.place!.address ?? p.fullText;

    // Devolver a la página anterior la dirección y coordenadas seleccionadas
    Navigator.pop(context, {
      "direccion": direccion,
      "lat": loc.lat,
      "lng": loc.lng,
    });
  }

  // Método build para mostrar la interfaz de búsqueda de direcciones,
  //con un campo de texto para ingresar la dirección
  //y una lista de sugerencias que se actualiza a medida que el usuario escribe.
  //Al seleccionar una sugerencia, se obtiene la ubicación y dirección completa
  //y se devuelve a la página anterior.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Buscar dirección",
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Introduce una dirección",
                border: OutlineInputBorder(),
              ),
              onChanged: buscar,
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: sugerencias.length,
              itemBuilder: (_, i) {
                final p = sugerencias[i];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(p.fullText),
                  onTap: () => seleccionar(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
