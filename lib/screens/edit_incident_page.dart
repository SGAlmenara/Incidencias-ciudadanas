import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'place_search_page.dart';
import '../widgets/app_scaffold.dart';
import '../services/incident_service.dart';

// PÁGINA DE EDICIÓN DE INCIDENCIA: PERMITE EDITAR TÍTULO, DESCRIPCIÓN, ESTADO, DIRECCIÓN Y FOTOS.
// SI EL USUARIO ES ADMINISTRADOR, PUEDE EDITAR EL ESTADO; SI ES USUARIO NORMAL,
//EL ESTADO NO SE MUESTRA NI SE PUEDE EDITAR.
class EditIncidentPage extends StatefulWidget {
  final Map<String, dynamic> incident;

  const EditIncidentPage({super.key, required this.incident});

  @override
  State<EditIncidentPage> createState() => _EditIncidentPageState();
}

class _EditIncidentPageState extends State<EditIncidentPage> {
  late TextEditingController tituloCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController latCtrl;
  late TextEditingController lngCtrl;
  late TextEditingController calleCtrl;

  late String estado;

  bool isAdmin = false;
  bool loadingRole = true;

  List<String> nuevasImagenes = [];
  List<String> imagenesExistentes = [];
  static const int maxFotos = 3;

  // Método para cargar el rol del usuario al iniciar la página,
  // verificando si es administrador o no para mostrar u ocultar ciertas opciones de edición.
  @override
  void initState() {
    super.initState();

    tituloCtrl = TextEditingController(text: widget.incident['titulo']);
    descripcionCtrl = TextEditingController(
      text: widget.incident['descripcion'],
    );
    latCtrl = TextEditingController(
      text: widget.incident['latitud'].toString(),
    );
    lngCtrl = TextEditingController(
      text: widget.incident['longitud'].toString(),
    );
    calleCtrl = TextEditingController(text: widget.incident['direccion'] ?? "");
    estado = widget.incident['estado'];

    imagenesExistentes =
        (widget.incident['img_url'] as List?)?.cast<String>() ?? [];

    _loadUserRole();
  }

  // Método para liberar los controladores de texto al cerrar la página, evitando fugas de memoria.
  @override
  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    calleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        loadingRole = false;
        isAdmin = false;
      });
      return;
    }

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUser.id)
        .maybeSingle();

    setState(() {
      isAdmin = data != null && data['role'] == 'admin';
      loadingRole = false;
    });
  }

  // Seleccionar varias imágenes con límite
  Future<void> _pickImages() async {
    final totalActual = imagenesExistentes.length + nuevasImagenes.length;

    if (totalActual >= maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Máximo 3 fotos por incidencia")),
      );
      return;
    }

    final picker = ImagePicker();
    final files = await picker.pickMultiImage();

    if (files.isNotEmpty) {
      if (totalActual + files.length > maxFotos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No puedes añadir más de 3 fotos")),
        );
        return;
      }

      for (final file in files) {
        final bytes = await file.readAsBytes();
        nuevasImagenes.add(base64Encode(bytes));
      }
      setState(() {});
    }
  }

  // Abrir buscador de direcciones
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
        calleCtrl.text = result["direccion"];
        latCtrl.text = result["lat"].toString();
        lngCtrl.text = result["lng"].toString();
      });
    }
  }

  // Guardar cambios con validación
  Future<void> _guardarCambios() async {
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

    if (calleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar una dirección")),
      );
      return;
    }

    final lat = double.tryParse(latCtrl.text);
    final lng = double.tryParse(lngCtrl.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ubicación inválida")));
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Guardando cambios...")));

      final estadoFinal = isAdmin ? estado : widget.incident['estado'];

      final imagenesFinales = [...imagenesExistentes, ...nuevasImagenes];

      await IncidentService().updateIncident(
        id: widget.incident['id'].toString(),
        titulo: tituloCtrl.text,
        descripcion: descripcionCtrl.text,
        estado: estadoFinal,
        lat: lat,
        lng: lng,
        direccion: calleCtrl.text,
        imagenes: imagenesFinales,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incidencia actualizada correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
  }

  //Metodo build para mostrar la interfaz de edición de la incidencia,
  //con campos para título, descripción, estado, dirección y fotos.
  //También incluye validaciones y manejo de imágenes.
  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todasLasImagenes = [...imagenesExistentes, ...nuevasImagenes];

    return AppScaffold(
      title: "Editar incidencia",
      isAdmin: isAdmin,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(labelText: "Descripción"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: estado,
              decoration: const InputDecoration(labelText: "Estado"),
              items: const [
                DropdownMenuItem(value: "pendiente", child: Text("Pendiente")),
                DropdownMenuItem(
                  value: "en_proceso",
                  child: Text("En proceso"),
                ),
                DropdownMenuItem(value: "resuelta", child: Text("Resuelta")),
              ],
              onChanged: isAdmin ? (v) => setState(() => estado = v!) : null,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: calleCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Dirección"),
              onTap: _abrirBuscadorDireccion,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Latitud"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lngCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Longitud"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Agregar fotos"),
              ),
            ),

            const SizedBox(height: 20),

            if (todasLasImagenes.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: todasLasImagenes.map((img) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  body: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Center(
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 1,
                                        maxScale: 4,
                                        child: Image.memory(
                                          base64Decode(img),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
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
                                  if (imagenesExistentes.contains(img)) {
                                    imagenesExistentes.remove(img);
                                  } else {
                                    nuevasImagenes.remove(img);
                                  }
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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _guardarCambios,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text("Editar incidencia"),
            ),
          ],
        ),
      ),
    );
  }
}
