import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

import '../widgets/app_scaffold.dart';
import '../services/incident_service.dart';
import 'place_search_page.dart';
import '../widgets/back_fab.dart'; // IMPORTANTE

class CreateIncidentPage extends StatefulWidget {
  const CreateIncidentPage({super.key});

  @override
  State<CreateIncidentPage> createState() => _CreateIncidentPageState();
}

class _CreateIncidentPageState extends State<CreateIncidentPage> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();

  double? lat;
  double? lng;

  List<String> imagenes = [];
  static const int maxFotos = 3;

  Future<void> _pickImages() async {
    if (imagenes.length >= maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Máximo 3 fotos por incidencia")),
      );
      return;
    }

    final picker = ImagePicker();
    final files = await picker.pickMultiImage();

    if (files.isNotEmpty) {
      if (imagenes.length + files.length > maxFotos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No puedes añadir más de 3 fotos")),
        );
        return;
      }

      for (final file in files) {
        final bytes = await file.readAsBytes();
        imagenes.add(base64Encode(bytes));
      }
      setState(() {});
    }
  }

  Future<void> _abrirBuscadorDireccion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlaceSearchPage(apiKey: "AIzaSyCf19gvFJIf6D2wbJwE3vVoJgWCoGrNwoo"),
      ),
    );

    if (result != null) {
      setState(() {
        direccionCtrl.text = result["direccion"];
        lat = result["lat"];
        lng = result["lng"];
      });
    }
  }

  Future<void> _usarUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activa la ubicación del dispositivo")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      lat = pos.latitude;
      lng = pos.longitude;

      final placemarks = await placemarkFromCoordinates(lat!, lng!);
      final place = placemarks.first;

      final direccion = [
        place.street?.isNotEmpty == true ? place.street : place.thoroughfare,
        place.locality,
        place.postalCode,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(", ");

      setState(() {
        direccionCtrl.text = direccion;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener la ubicación: $e")),
      );
    }
  }

  Future<void> _crearIncidencia() async {
    if (tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("El título es obligatorio")));
      return;
    }

    if (descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La descripción es obligatoria")),
      );
      return;
    }

    if (direccionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar una dirección")),
      );
      return;
    }

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ubicación inválida")));
      return;
    }

    try {
      await IncidentService().createIncident(
        tituloCtrl.text,
        descripcionCtrl.text,
        lat!,
        lng!,
        direccionCtrl.text,
        imagenes,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al crear incidencia: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppScaffold(
          title: "Crear incidencia",
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: "Título",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: descripcionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: direccionCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Dirección",
                    border: OutlineInputBorder(),
                  ),
                  onTap: _abrirBuscadorDireccion,
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text("Usar mi ubicación actual"),
                  onPressed: _usarUbicacionActual,
                ),

                const SizedBox(height: 10),
                Text("Latitud: ${lat?.toStringAsFixed(6) ?? '---'}"),
                Text("Longitud: ${lng?.toStringAsFixed(6) ?? '---'}"),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Agregar fotos"),
                  onPressed: _pickImages,
                ),
                const SizedBox(height: 10),

                if (imagenes.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: imagenes.map((img) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[200],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.memory(
                                base64Decode(img),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      imagenes.remove(img);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text("Crear incidencia"),
                    onPressed: _crearIncidencia,
                  ),
                ),
              ],
            ),
          ),
        ),

        // BOTÓN FLOTANTE ABAJO A LA IZQUIERDA
        const Positioned(bottom: 20, left: 20, child: BackFAB()),
      ],
    );
  }
}
