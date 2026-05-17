---
name: project-worterabenteuer
description: "WörterAbenteuer — Flutter app for Fer's kid(s) to learn German vocabulary, Sprint-based development plan"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9344a2c9-3bd8-452b-a6b9-0107641502ef
---

**WörterAbenteuer** — Flutter app for children (ages 7-12) learning German as a second language (Spanish speakers).

**Location:** `C:\Users\ferbu\worterabenteuer\`
**Schema file:** `C:\Users\ferbu\worterabenteuer\WORTERABENTEUER_SCHEMA.html` (visual architecture reference v2)
**Stack:** Flutter 3.41.9 + Firebase + Riverpod + go_router + ML Kit + Claude API (Haiku via Cloud Functions)

**Why:** Personal app for Fer's family to help kids memorize weekly German school vocabulary. Reward system ties study time to screen time approval by parents.

**Current status (2026-05-17):**
- Sprint 1 ✅ COMPLETE — Foundation (commit bfa7a5d/b332c60)
- Sprint 2 ✅ COMPLETE — Family management (commit 977ae62)
- Sprint 3 ✅ COMPLETE — Vocabulary import + OCR (commit 901b27b)
- Sprint 4 ✅ COMPLETE — Lesson list + study modes (commit 95fcf9c)
- Sprint 5 ✅ COMPLETE — Handwriting (commit 137a4b4, CodyVPS 2026-05-17)
- Sprint 6 ✅ COMPLETE — Voice (commit 65bea22, CodyVPS 2026-05-17)
- Sprint 7 ✅ COMPLETE — Screen Time Reward (commit e4c8b0d, CodyVPS 2026-05-17)
- Sprint 8 ✅ COMPLETE — Session tracking + Weekly Report (commit 0d9ebfc, CodyVPS 2026-05-17)
- Sprint 9 ✅ COMPLETE — Lesson progression + Extra Vocab (commit 62eced3, CodyVPS 2026-05-17)
- Sprint 10 ✅ COMPLETE — Polish: streak, rules, onboarding (commit 1821336, CodyVPS 2026-05-17)
- Sprint 11 ✅ COMPLETE — Firebase deploy + build config (commit 354ff0e, CodyVPS 2026-05-17)

**ALL 11 SPRINTS COMPLETE — app ready for `flutterfire configure` + deploy**

---

**Sprint 1 deliverables:**
- Full directory structure, pubspec.yaml (170 deps resolved), design system (AppColors, AppTextStyles, AppTheme)
- go_router auth guard, Google + Apple Sign-In, SplashScreen, LoginScreen
- firebase_options.dart placeholder — user must run `flutterfire configure` before first run

**Sprint 2 deliverables:**
- ChildProfile Hive model (@HiveType typeId:0) with Firestore serialization, child_profile.g.dart generated
- FirestoreService: watchChildren(), createChild(), updateChild(), deleteChild(), approveScreenTime(), addPoints(), updateScreenTimePending()
- ParentAuthService: biometric first (local_auth), PIN fallback (flutter_secure_storage), PIN setup flow
- Screens: ChildSelectionScreen (grid cards with weekly progress bar + points), CreateChildScreen (avatar emoji grid, age 7-12, auto-level), ParentLoginScreen (dark PIN pad + biometric), ParentDashboardScreen (child stat cards + 4 action buttons)
- Hive adapters registered in main.dart

**Sprint 3 deliverables:**
- OcrService: ML Kit text recognition, X-midpoint column split (centerX < midX*1.1 = German), Y-proximity matching within 60px, German heuristics (der/die/das/ein/ü/ö/ä/ß), sentence detection (length>20 or ends .!? or wordCount>3)
- ImportVocabScreen: source selection (Antón screenshot / printed sheet), camera + gallery buttons, manual entry
- OcrReviewScreen: editable German/Spanish pairs, child dropdown, level FilterChips, confidence banner, batch save via firestoreService.createLesson() (Firestore batch write for lesson + all vocab items)
- Lesson model (@HiveType typeId:1), VocabItem model (@HiveType typeId:2), lesson.g.dart + vocab_item.g.dart generated

**Sprint 4 deliverables:**
- lesson_providers.dart: selectedChildProvider (StateProvider), selectedLessonProvider (StateProvider), childLessonsProvider (StreamProvider), lessonVocabProvider (FutureProvider — single load, not stream)
- session_result.dart: SessionResult(pointsEarned, wordsAttempted, wordsCorrect, mode, lessonTitle) + accuracy getter
- LessonListScreen: streams lessons per child, status badges (assigned/in_progress/completed/perfect), circular progress, staggered animations
- LessonDetailScreen: gradient progress header, 4 mode buttons; voice+handwriting locked (requiresPerfect=true) until lesson.perfectRoundCompleted
- FlashcardScreen: 3D flip (AnimationController + Matrix4.rotationY), easy/hard re-queue, +1pt per flip
- KeyboardScreen: Spanish prompt → type German, case-insensitive match, +2pts correct, German chars hint in TextField suffix
- LessonCompleteScreen: gradient (violet/sky ≥70%, mint/sky <70%), trophy/star/muscle emoji, stats row
- Router: /lessons, /lessons/detail, /study/flashcard, /study/keyboard, /study/voice (placeholder), /study/handwriting (placeholder), /study/complete
- ChildCard upgraded to ConsumerWidget — sets selectedChildProvider before navigation

---

**Game rules (from schema v2):**
- Word mastery = handwriting ONLY, no errors in one pass → sets `dominated = true`
- Voice correct = bonus only, not mastery → sets `voiceBonus = true` on already-dominated word
- Keyboard correct → +2pts, does NOT count as mastery
- Flash card viewed → +1pt, does NOT count as mastery
- Review round: collect failed words DURING session, play them ALL at the END
- Perfect round = review round with 0 errors → sets `perfectRoundCompleted = true`, unlocks `extraVocabUnlocked = true` on lesson, +20pts bonus
- Review round pass = +7pts (same as handwriting)
- Screen time ratio: 1 min study = 2.5 min screen time (AppConstants.screenTimeRatio)

**Points table:**
- Voice correct: +7pts (bonus)
- Handwriting no error: +7pts (+ dominates word)
- Keyboard correct: +2pts
- Flashcard viewed: +1pt
- Review round pass: +7pts (+ dominates word)
- Perfect round bonus: +20pts

**Key technical decisions:**
- `image_cropper: ^12.2.1` (not ^7.0.0) — web package conflict with firebase_core
- `withValues(alpha:)` instead of `withOpacity()` — Flutter 3.41+ API
- `Platform.isIOS` check for Apple Sign-In button visibility
- Orientation locked to portrait (both portraitUp and portraitDown)
- Hive adapters generated via `dart run build_runner build --delete-conflicting-outputs`
- `WoerterAbenteuerApp` (not WörterAbenteuer) — ö is illegal in Dart identifiers
- `CardThemeData` (not `CardTheme`) — Flutter 3.41+ ThemeData API change
- selectedChildProvider set in ConsumerWidget before navigation — screens read from provider, not GoRouter extra
- lessonVocabProvider is FutureProvider (single load per session) to avoid re-loading mid-session
- Anthropic API key + Google Speech key go in Cloud Functions ONLY — never in client code
- Hive logging from Lenny (Windows): `ssh root@100.116.43.22 python3 /root/hive/hive.py decide "CodyLenny" ...`

**File structure highlights:**
- `lib/core/router/app_router.dart` — GoRouter + AppRoutes constants
- `lib/core/services/firestore_service.dart` — all Firestore CRUD
- `lib/core/services/ocr_service.dart` — ML Kit OCR + column detection
- `lib/features/family/domain/models/child_profile.dart` — ChildProfile model
- `lib/features/lessons/domain/models/lesson.dart` — Lesson model
- `lib/features/lessons/domain/models/vocab_item.dart` — VocabItem model (has: dominated, voiceBonus, addedToReviewRound, reviewRoundPassed, handwrittenAttempts, handwrittenCorrect)
- `lib/features/lessons/presentation/providers/lesson_providers.dart` — all study providers
- `lib/features/study/domain/models/session_result.dart` — SessionResult
- `lib/features/study/presentation/screens/` — flashcard, keyboard, lesson_complete screens
- `lib/shared/widgets/kid_button.dart` — reusable large button
- `lib/shared/widgets/progress_bar.dart` — KidProgressBar

**Sprint 5 deliverables (CodyVPS, 2026-05-17):**
- `HandwritingScreen` — `lib/features/study/presentation/screens/handwriting_screen.dart`
- `_InkPainter` CustomPainter for stroke rendering (Path-based, rounded caps)
- ML Kit Digital Ink Recognition: DigitalInkRecognizer(languageCode: 'de'), auto-downloads model on first run
- Levenshtein distance for age-based tolerance (young 7-8: 2 errors, middle 9-10: 1, older 11-12: 0)
- State machine: mainRound → reviewRound → finish (pushReplacement to studyComplete)
- On correct: dominated=true, handwrittenCorrect++, +7pts to Firestore
- On incorrect (main round): addedToReviewRound=true; collected into reviewList
- Review round: failed words replayed; if all pass → perfectRoundCompleted + +20pts + lesson status='perfect'
- Router: /study/handwriting now routes to HandwritingScreen (was placeholder)
- Key technical: InkPoint(point: Offset, t: int ms); model download blocks verify until ready; `_recognizer.close()` in dispose

**Sprint 6 deliverables (CodyVPS, 2026-05-17):**
- `VoiceScreen` — `lib/features/study/presentation/screens/voice_screen.dart`
- `speech_to_text` v7, `localeId='de_DE'`, 8s listen / 2s pause-for silence
- Animated pulsing mic circle (ScaleTransition, AnimationController)
- Article stripping before Levenshtein: der/die/das/ein/eine removed from both sides
- Same age-based Levenshtein tolerance as handwriting (young:2 / middle:1 / older:0)
- Voice correct → `voiceBonus=true`, `voiceCorrect++`, +7pts; NOT dominated
- No review round — pure bonus mode (accessible only after perfectRoundCompleted)
- Skip button ("Saltar palabra") → calls _evaluateAnswer with empty spoken text
- Wire `/study/voice` route (was placeholder)

**Sprint 7 deliverables (CodyVPS, 2026-05-17):**
- `ApproveScreenTimeScreen` — `/parent/approve` (parent zone)
  - Lists only children with earnedScreenTimePending > 0
  - Slider per child (0..pending), "Todo (N min)" shortcut
  - Conversion preview: credit × 2.5 → screen time displayed
  - Calls `FirestoreService.approveScreenTime(childId, mins)` → increments approved, decrements pending
  - SnackBar confirmation on approve
- `RewardsScreen` — `/rewards` (child zone)
  - Hero card: approved screen time with gradient (green if >0, violet if 0)
  - Pending card: shows pending mins + their screen-time equivalent
  - How-it-works card: ratio, modes, perfect round, parent approval step
  - Points/streak summary row
  - Reads live from `childrenProvider` by child.id, falls back to selectedChildProvider
- `LessonListScreen` updated: 🎮 chip in AppBar showing `earnedScreenTimeApproved`min, taps → RewardsScreen
- Key technical: `firstOrNull` on list to get live child data; Slider `divisions` guards against 0

**Sprint 8 deliverables (CodyVPS, 2026-05-17):**
- `StudySession` model: id, childId, lessonId, lessonTitle, mode, pointsEarned, wordsAttempted, wordsCorrect, completedAt
  - `estimatedMinutes`: mode-based formula (flashcard:12s, keyboard:25s, handwriting:40s, voice:20s per word → ceil to min)
- `FirestoreService.recordSession()`: writes to `children/{id}/sessions/{sid}`, increments effectiveTimeMinutesWeek + Total
- `FirestoreService.getSessionsThisWeek(childId)`: queries last 7 days by completedAt descending
- `LessonCompleteScreen` → `ConsumerStatefulWidget`: `_recordSession()` in initState (flag guards against double-write), awards `estimatedMinutes` to `earnedScreenTimePending`, shows "+N min de crédito" hint row
- `WeeklyReportScreen`: FutureProvider.family per child, KPI grid (sessions/points/words/time), accuracy + top-mode pills, last-3-sessions list
- Key: `_weeklySessionsProvider` is a FutureProvider.family<List<StudySession>, String>(childId)

**Sprint 9 deliverables (CodyVPS, 2026-05-17):**
- `FirestoreService.dominateWord()`: batch — vocab item update + `FieldValue.increment(wordsDominated)` + `status=in_progress`; then `_checkLessonCompletion()` reads lesson doc and sets `completed` if `wordsDominated>=wordsTotal`
- `FirestoreService.setPerfectRound()`: atomic `perfectRoundCompleted=true, extraVocabUnlocked=true, status=perfect`
- `FirestoreService.addExtraVocabToLesson()`: batch adds VocabItems, `FieldValue.increment(wordsTotal)`, sets correct order
- `HandwritingScreen` fixed: correct → `dominateWord()` (not `updateVocabItem`); perfect finish → `setPerfectRound()` (not `updateLessonStatus`)
- `ExtraVocabScreen`: 5 A1 packs hardcoded (Tiere, Essen, Zuhause, Farben, Kleidung — 8 words each); bottom-sheet word preview; batch-adds on confirm; tracks added packs in session state; graceful if adding multiple packs
- `LessonDetailScreen`: extraVocabUnlocked banner is now tappable, navigates to `/extra-vocab`
- Key: `_checkLessonCompletion` is a private read after batch write — avoids transaction complexity but has slight race condition risk (acceptable for this use case)

**Sprint 10 deliverables (CodyVPS, 2026-05-17):**
- `FirestoreService.recordSession()` streak logic: reads `lastActiveDate` from child doc, computes streak: broken → reset to 1, consecutive day → increment, same-day → skip; updates `currentStreak`, `longestStreak`, `lastActiveDate` atomically with effectiveTime increments
- `LessonCompleteScreen._recordSession()`: wrapped in try-catch; Firestore offline cache queues writes when offline
- `firestore.rules`: `families/{familyId}` + `{allSubcollections=**}` locked to `request.auth.uid == familyId`; catch-all deny; ready for `firebase deploy --only firestore:rules`
- `OnboardingScreen`: 3-page PageView with gradient backgrounds (violet→sky, mint→sky, grass→mint); animated emoji hero, title, subtitle, bullets; dot indicator; skip button on non-last pages; persists `onboarding_done_v1` via `FlutterSecureStorage`
- `SplashScreen`: calls `hasSeenOnboarding()` after auth resolves; first launch → `/onboarding`, returning users → `/children`
- Key: streak same-day guard prevents double-counting if multiple sessions in one day

**Sprint 11 plan (Firebase deploy + build config):**
- `firebase.json` with Firestore rules config
- `SETUP.md` deploy instructions (flutterfire configure, firebase deploy --only firestore:rules)
- `google-services.json` + `GoogleService-Info.plist` setup notes
- Android: minSdkVersion=24, package name, signing config
- iOS: bundle ID, entitlements for local_auth + speech_to_text
- Final `flutter build apk --release` + `flutter build ios` validation checklist

**Sprint 11 deliverables (CodyVPS, 2026-05-17):**
- `android/app/build.gradle.kts`: `applicationId=com.worterabenteuer.app`, `minSdk=24` (ML Kit + local_auth), `multiDexEnabled=true`, release with `isMinifyEnabled=true`, `isShrinkResources=true`, proguard rules
- `android/app/src/main/AndroidManifest.xml`: INTERNET, RECORD_AUDIO, CAMERA, READ_MEDIA_IMAGES, USE_BIOMETRIC, USE_FINGERPRINT, VIBRATE permissions; `android:label="WörterAbenteuer"`, `android:screenOrientation="portrait"`, `android:usesCleartextTraffic="false"`; queries block for image_cropper
- `ios/Runner/Info.plist`: NSMicrophoneUsageDescription, NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSFaceIDUsageDescription, NSSpeechRecognitionUsageDescription (all in Spanish); portrait+portraitUpsideDown only; `CADisableMinimumFrameDurationOnPhone=true` for ProMotion
- `firebase.json`: `{"firestore": {"rules": "firestore.rules", "indexes": "firestore.indexes.json"}}`
- `firestore.indexes.json`: 4 compound indexes — sessions(completedAt DESC), sessions(childId+completedAt DESC), vocab_items(lessonId+order ASC), lessons(childId+assignedAt DESC)
- `SETUP.md`: full deploy guide with flutterfire configure, firebase deploy, Android keystore setup, iOS entitlements, Cloud Functions secrets, sprint status table
- Key: API keys (Anthropic, Google Speech) go in Cloud Functions secrets ONLY; `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` must be in .gitignore
