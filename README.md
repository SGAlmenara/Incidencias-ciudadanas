## Incidencias Ciudadanas – Aplicación Flutter + Supabase
Aplicación web desarrollada en Flutter Web para la gestión de incidencias ciudadanas en el municipio de Cantillana.
Permite a los ciudadanos registrar incidencias con fotos, geolocalización y dirección, mientras que el Ayuntamiento dispone de un panel de administración para gestionarlas.

Proyecto desarrollado como parte del Checkpoint 2 del módulo de Desarrollo de Aplicaciones Multiplataforma (DAM).

# Tecnologías utilizadas
Flutter Web

Supabase (Auth, Database, Storage)

Google OAuth

Google Maps + Places API

Arquitectura Repository + Service

Plesk (hosting)

# Estructura del proyecto
Código
lib/
 ├── models/
 ├── services/
 ├── repositories/
 ├── screens/
 ├── widgets/
 └── main.dart
deploy/        ← build web para despliegue en Plesk
assets/
# Modelo de datos
Tabla profiles
id (UUID, PK)

email

role (user/admin)

Tabla incidencias
id (UUID, PK)

user_id (FK → profiles.id)

titulo

descripcion

estado (pendiente, en_proceso, resuelta)

latitud

longitud

direccion

imagenes (array de strings)

fecha

# Autenticación
Registro con email/contraseña

Login con email/contraseña

Login con Google OAuth

Detección automática de sesión con onAuthStateChange

Redirección según rol (admin/usuario)

# Funcionalidades principales
Usuario
Crear incidencia con:

Fotos múltiples

Geolocalización

Dirección mediante Google Places

Ver sus incidencias

Ver detalle con mapa

Filtrar por estado

Administrador
Ver todas las incidencias

Filtrar por estado

Cambiar estado

Ver detalle completo

# Estado actual del proyecto (Checkpoint 2)
Modelo de datos final implementado

Autenticación funcional

Roles funcionando

CRUD de incidencias

Geolocalización y Places integrados

Panel admin en desarrollo

# Despliegue
https://alumno25.fpcantillana.org/


# Cómo ejecutar el proyecto
bash
flutter pub get
flutter run -d chrome
# Autora
Sonia González Almenara  
DAM – Desarrollo de Aplicaciones Multiplataforma - IES Cantillana
