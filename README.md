# Mirecetario

Mirecetario es una aplicación Flutter para gestionar recetas, planificar menús semanales y generar automáticamente la lista de la compra.

## Características

- Gestión de recetas con ingredientes y cantidades.
- Planificación semanal de menús.
- Generación automática de la lista de la compra agrupando ingredientes.
- Sincronización de datos entre plataformas.
- Compatible con Android, escritorio (Windows, Linux, macOS) y Web.

## Instalación y ejecución

### Android y Escritorio
1. Clona este repositorio.
2. Instala las dependencias:
   ```sh
   flutter pub get
   ```
3. Ejecuta la app:
   ```sh
   flutter run -d <dispositivo>
   ```

### Web
1. Instala las dependencias:
   ```sh
   flutter pub get
   ```
2. Ejecuta la app en modo web:
   ```sh
   flutter run -d chrome
   ```

## Notas sobre compatibilidad
- Para la gestión de base de datos, la app utiliza `drift` y selecciona el backend adecuado según la plataforma:
  - **Web:** usa IndexedDB.
  - **Android y Escritorio:** usa SQLite.
- No es necesario cambiar el código para cada plataforma, la app detecta el entorno automáticamente.

## Estructura del proyecto
- `lib/` Código principal de la aplicación.
- `features/` Funcionalidades principales (recetas, lista de la compra, planificador).
- `core/database/` Lógica de base de datos y adaptadores multiplataforma.
- `test/` Pruebas unitarias y de widgets.

## Dependencias principales
- [Flutter](https://flutter.dev/)
- [Drift](https://drift.simonbinder.eu/)
- [Riverpod](https://riverpod.dev/)

## Licencia

MIT
