import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

import '../widgets/app_scaffold.dart';
import '../services/incident_service.dart';
import 'place_search_page.dart';
import '../widgets/back_fab.dart'; // IMPORTANTE

// PÁGINA DE CREACIÓN DE INCIDENCIA: PERMITE A USUARIOS NORMALES
//CREAR NUEVAS INCIDENCIAS CON TÍTULO, DESCRIPCIÓN, DIRECCIÓN
//(CON BUSCADOR O USANDO UBICACIÓN ACTUAL) Y HASTA 3 FOTOS.
//INCLUYE VALIDACIONES ANTES DE CREAR LA INCIDENCIA.
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

  // CARGAR ROL AL INICIAR PÁGINA
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

  // Método para abrir la página de búsqueda de direcciones usando Google Places API.
  //Al seleccionar una dirección, se llenan los campos de dirección y coordenadas.
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

  // Método para usar la ubicación actual del dispositivo y convertirla en una dirección legible,
  // llenando los campos correspondientes. Maneja permisos y errores.
  Future<void> _usarUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activa la ubicación del dispositivo")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Debes conceder permiso de ubicación"),
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Permiso de ubicación bloqueado. Habilítalo en la configuración del navegador/dispositivo.",
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latValue = pos.latitude;
      final lngValue = pos.longitude;

      if (!mounted) return;
      setState(() {
        lat = latValue;
        lng = lngValue;
      });

      var direccion =
          "${latValue.toStringAsFixed(6)}, ${lngValue.toStringAsFixed(6)}";

      try {
        final placemarks = await placemarkFromCoordinates(latValue, lngValue);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parsedDireccion = [
            place.street?.isNotEmpty == true
                ? place.street
                : place.thoroughfare,
            place.locality,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(", ");

          if (parsedDireccion.isNotEmpty) {
            direccion = parsedDireccion;
          }
        }
      } catch (_) {
        // En web, la geocodificación inversa puede fallar según el navegador.
        // Se mantiene una dirección mínima con coordenadas para no bloquear el flujo.
      }

      if (!mounted) return;
      setState(() {
        direccionCtrl.text = direccion;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ubicación obtenida correctamente")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener la ubicación: $e")),
      );
    }
  }

  // Método para validar los campos y crear la incidencia usando IncidentService.
  //Muestra mensajes de error si faltan campos o si la ubicación es inválida.
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

  // Método build para mostrar la interfaz de creación de incidencia,
  //con campos para título, descripción, dirección
  //(con buscador y opción de usar ubicación actual) y agregar fotos.
  // También incluye validaciones antes de crear la incidencia.
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
                    onPressed: _crearIncidencia,
                    child: const Text("Crear incidencia"),
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
