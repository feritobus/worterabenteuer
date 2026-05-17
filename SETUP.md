# WörterAbenteuer — Setup & Deploy Guide

## Prerequisites

- Flutter 3.41.9+
- Firebase CLI (`npm install -g firebase-tools`)
- Xcode 15+ (iOS builds)
- Android Studio / SDK (Android builds)
- A Firebase project with **Authentication**, **Firestore**, and **Storage** enabled

---

## 1. Clone the repo

```bash
git clone https://github.com/feritobus/worterabenteuer.git
cd worterabenteuer
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 2. Firebase configuration

### 2a. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2b. Log in and configure

```bash
firebase login
flutterfire configure
```

Select your Firebase project when prompted. This generates:
- `lib/firebase_options.dart` ← **never commit this file**
- `android/app/google-services.json` ← **never commit**
- `ios/Runner/GoogleService-Info.plist` ← **never commit**

Make sure those files are in `.gitignore`.

### 2c. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## 3. Android build

### 3a. Signing (release)

Create a keystore:
```bash
keytool -genkey -v -keystore ~/worterabenteuer-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias worterabenteuer
```

Create `android/key.properties` (do NOT commit):
```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=worterabenteuer
storeFile=<path-to>/worterabenteuer-release.jks
```

Update `android/app/build.gradle.kts` release block to use `signingConfigs.getByName("release")` (currently wired to `debug` for development convenience).

### 3b. Build APK / AAB

```bash
# Debug APK
flutter build apk --debug

# Release APK (local testing)
flutter build apk --release

# Release AAB (Play Store)
flutter build appbundle --release
```

Minimum SDK: **24** (Android 7.0) — required by ML Kit Digital Ink + local_auth.

---

## 4. iOS build

### 4a. Bundle ID

Open `ios/Runner.xcworkspace` in Xcode.  
Set **Bundle Identifier** to `com.worterabenteuer.app` (or your team's ID).

### 4b. Entitlements

Ensure these capabilities are enabled in Xcode:
- **Sign in with Apple** (for `sign_in_with_apple` package)
- **LocalAuthentication / FaceID** (for `local_auth` package)
- **Microphone** (already in Info.plist)

### 4c. Build

```bash
flutter build ios --release
```

Open the generated Xcode project, set your Team, and archive via **Product → Archive**.

---

## 5. Cloud Functions (API keys)

The Anthropic API key (Claude Haiku) and Google Speech-to-Text API key **must** live in Cloud Functions environment — never in the client app.

```bash
cd functions
firebase functions:secrets:set ANTHROPIC_KEY
firebase functions:secrets:set GOOGLE_SPEECH_KEY
firebase deploy --only functions
```

---

## 6. Sprint completion status

| Sprint | Feature | Status |
|--------|---------|--------|
| 1 | Foundation — routing, auth, design system | ✅ |
| 2 | Family management — children, parent PIN | ✅ |
| 3 | Vocabulary import — OCR, manual entry | ✅ |
| 4 | Lesson list + study modes (flashcard, keyboard) | ✅ |
| 5 | Handwriting study mode (ML Kit Digital Ink) | ✅ |
| 6 | Voice study mode (speech_to_text de_DE) | ✅ |
| 7 | Screen time reward system | ✅ |
| 8 | Session tracking + Weekly Report | ✅ |
| 9 | Lesson progression + Extra Vocab packs | ✅ |
| 10 | Polish — streak, Firestore rules, onboarding | ✅ |
| 11 | Firebase deploy + build config | ✅ |

---

## 7. Architecture notes

- **State management**: Riverpod (providers in `lib/features/*/presentation/providers/`)
- **Navigation**: go_router with auth guard (`lib/core/router/app_router.dart`)
- **Local storage**: Hive for models; flutter_secure_storage for PIN + onboarding flag
- **Firestore structure**: `families/{uid}/children/{cid}/sessions/{sid}`, `families/{uid}/lessons/{lid}/vocab_items/{vid}`
- **Offline support**: Firestore offline cache — writes are queued when offline and synced when connection returns
- **Word mastery**: handwriting-only, no errors in one pass → `dominated = true`
- **Screen time ratio**: 1 min study = 2.5 min screen time (`AppConstants.screenTimeRatio`)
