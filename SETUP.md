# WörterAbenteuer — Configuración Inicial

## Requisitos previos
- Flutter 3.16+ (tienes 3.41.9 ✓)
- Cuenta de Google (para Firebase)
- Cuenta de Apple Developer (para Sign in with Apple en iOS)

## Paso 1 — Crear proyecto Firebase

1. Ve a https://console.firebase.google.com
2. Crea un nuevo proyecto: **worterabenteuer**
3. Habilita los siguientes servicios:
   - Authentication → Google y Apple
   - Firestore Database → modo producción
   - Storage
   - Functions
   - Analytics
   - Crashlytics

## Paso 2 — Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Paso 3 — Configurar Firebase en el proyecto

```bash
cd worterabenteuer
flutterfire configure
```

Esto reemplaza automáticamente `lib/firebase_options.dart` con los valores reales.

## Paso 4 — Instalar dependencias

```bash
flutter pub get
```

## Paso 5 — Correr la app

```bash
# Android
flutter run -d android

# iOS (requiere Mac con Xcode)
flutter run -d ios
```

## Notas importantes

- **Sign in with Apple** solo funciona en dispositivos iOS reales o simulador.
  En Android, solo aparece el botón de Google.
- Nunca subas `firebase_options.dart` con valores reales a un repo público.
- Las API keys de Cloud Speech y Anthropic van en **Cloud Functions**,
  nunca en el código cliente.

## Estructura de la app

```
Sprint 1 ✅ — Foundation (login, diseño)
Sprint 2 ⬜ — Perfiles de niños
Sprint 3 ⬜ — Importar vocabulario con OCR
Sprint 4 ⬜ — Flash Cards y Teclado
Sprint 5 ⬜ — Escritura a mano
Sprint 6 ⬜ — Voz + IA
Sprint 7 ⬜ — Rondas y lógica
Sprint 8 ⬜ — Tiempo y recompensas
Sprint 9 ⬜ — Reportes de padres
Sprint 10 ⬜ — Pulido y testing
Sprint 11 ⬜ — Publicación
```
