import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

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

  Future<void> buscar(String query) async {
    if (query.length < 3) {
      setState(() => sugerencias = []);
      return;
    }

    final result = await places.findAutocompletePredictions(query);
    setState(() => sugerencias = result.predictions);
  }

  Future<void> seleccionar(AutocompletePrediction p) async {
    final details = await places.fetchPlace(
      p.placeId,
      fields: [PlaceField.Location, PlaceField.Address],
    );

    final loc = details.place!.latLng!;
    final direccion = details.place!.address ?? p.fullText;

    Navigator.pop(context, {
      "direccion": direccion,
      "lat": loc.lat,
      "lng": loc.lng,
    });
  }

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
