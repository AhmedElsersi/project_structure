# New project checklist

The ordered steps to turn a copy of `flutter_template` into a shippable app. The
[`/new-project`](../.claude/commands/new-project.md) slash command automates steps 1–2 and the
first verification, then walks you through the rest. Placeholders in the template are marked
`{{BRAND_PRIMARY}}`, `{{FONT_FAMILY}}`, `{{APP_LOGO}}`, `{{APPLICATION_ID}}`, `AppName` and
`com.example.app`. Search for them: `grep -rn "{{\|AppName\|com.example.app" lib android ios assets .env.example`.

- [ ] [1. Copy and rename](#1-copy-and-rename)
- [ ] [2. Environment](#2-environment)
- [ ] [3. Brand colours and fonts](#3-brand-colours-and-fonts)
- [ ] [4. App name in Arabic and English](#4-app-name-in-arabic-and-english)
- [ ] [5. App icons and splash](#5-app-icons-and-splash)
- [ ] [6. Android signing](#6-android-signing)
- [ ] [7. iOS signing](#7-ios-signing)
- [ ] [8. Permissions](#8-permissions)
- [ ] [9. Flavors](#9-flavors)
- [ ] [10. Store listing, privacy and account deletion](#10-store-listing-privacy-and-account-deletion)
- [ ] [11. CI secrets](#11-ci-secrets)
- [ ] [12. Replace the sample feature](#12-replace-the-sample-feature)
- [ ] [13. Production: mocks off](#13-production-mocks-off)
- [ ] [14. Opt-in modules](#14-opt-in-modules)
- [ ] [15. Final verification](#15-final-verification)

---

## 1. Copy and rename

```bash
# from project_structure/
rsync -a --exclude build --exclude .dart_tool --exclude .env --exclude 'ios/Pods' \
  --exclude '.idea' --exclude '*.iml' --exclude '.flutter-plugins-dependencies' \
  --exclude 'android/local.properties' --exclude 'ios/Flutter/Generated.xcconfig' \
  --exclude 'ios/Flutter/ephemeral' --exclude 'ios/Flutter/flutter_export_environment.sh' \
  flutter_template/ ../my_app/
cp CLAUDE.md ../my_app/CLAUDE.md
rsync -a --exclude _analysis docs/ ../my_app/docs/   # optional: keep the docs next to the code
cd ../my_app

dart run tool/rename_app.dart --package my_app --name "My App" --id com.example.myapp --dry-run
dart run tool/rename_app.dart --package my_app --name "My App" --id com.example.myapp
flutter clean && flutter pub get
git init                                        # first commit only when you're ready
```

`rename_app.dart` reads the **current** values from the files, so you can re-run it. It updates:

| File | What |
|---|---|
| `pubspec.yaml` | `name:` (and `AppName` in the description) |
| `lib/`, `test/`, `tool/`, `integration_test/` | `package:app_template/` → `package:my_app/` |
| `android/app/build.gradle.kts` | `namespace` + `applicationId` |
| `android/app/src/main/kotlin/...` | `MainActivity` package, moved to the new folder |
| `android/app/src/main/AndroidManifest.xml` | `android:label` |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (+ `.RunnerTests`). iOS gets `-` instead of `_` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName` |
| `assets/translations/{en,ar}.json` | `app.name`, only while it is still the placeholder |
| `.env.example` | the store URL id |

Rules: the package name is `snake_case` and not a reserved word. The application id is reverse-DNS
(`com.company.app`). It is **permanent** once published, so choose it carefully.

## 2. Environment

```bash
cp .env.example .env          # gitignored
```

Fill in `APP_FLAVOR=dev` and `BASE_URL=` (leave it empty to keep using the mock backend while the
API doesn't exist yet), plus the store URLs once the store records exist. Run with
`flutter run --dart-define-from-file=.env`, and add the same argument to your IDE run
configurations. Rules: [CONVENTIONS.md#environment](CONVENTIONS.md#environment).

## 3. Brand colours and fonts

1. **Colours**: set `AppColors.brandSeed` in `lib/core/theme/app_colors.dart` (`{{BRAND_PRIMARY}}`).
   The whole light and dark `ColorScheme` derives from it. If the brand has a fixed secondary or
   tertiary colour, add it to `AppColors` and `.copyWith(...)` the scheme in `AppTheme._build`.
   Adjust the semantic tones (success/warning/info) only if they clash. Then run
   `flutter test test/core/theme/` (the contrast tests must stay green).
2. **Font**: one family that covers Arabic and Latin (Cairo, Tajawal, IBM Plex Sans Arabic, Noto
   Sans Arabic...). Add the files and their licence under `assets/fonts/`, then:

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Variable.ttf     # or one file per weight:
        # - asset: assets/fonts/Cairo-Regular.ttf
        # - asset: assets/fonts/Cairo-SemiBold.ttf
        #   weight: 600
```

```dart
// lib/core/theme/app_typography.dart
static const String? fontFamily = 'Cairo'; // {{FONT_FAMILY}}
```

   Check the Arabic line heights on a real screen. The type scale sets explicit `height`s, so tune
   them in `AppTypography.base` if the font needs more room.
3. **Logo**: replace `FlutterLogo` in `lib/shared/screens/splash_screen.dart` (`{{APP_LOGO}}`) with
   the brand asset (text-free), matching the native splash (step 5).

## 4. App name in Arabic and English

| Where | Set |
|---|---|
| `assets/translations/ar.json` / `en.json` → `app.name` | Used by `onGenerateTitle` (task switcher, web title) |
| Android launcher label | `rename_app.dart` set `android:label="My App"`. For a localized label, create `android/app/src/main/res/values/strings.xml` (`<string name="app_name">My App</string>`) and `values-ar/strings.xml` (`<string name="app_name">تطبيقي</string>`), then use `android:label="@string/app_name"` |
| iOS home-screen name | `CFBundleDisplayName` is set. For Arabic, add `ios/Runner/ar.lproj/InfoPlist.strings` with `"CFBundleDisplayName" = "تطبيقي";` (and `en.lproj`), and add both files to the Runner target in Xcode. `CFBundleLocalizations` already lists `ar` and `en` |
| Store listings | Arabic and English titles (step 10) |

## 5. App icons and splash

Both are **dev dependencies** with their config in `pubspec.yaml`. Source images live in
`assets/branding/`; they are not app assets, so don't list them under `flutter: assets:`.

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.8

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/branding/icon.png"                 # 1024×1024 PNG
  remove_alpha_ios: true                                 # App Store rejects transparent icons
  adaptive_icon_background: "#FFFFFF"                    # brand background
  adaptive_icon_foreground: "assets/branding/icon_foreground.png"   # 432×432, logo inside the 66% safe zone
  adaptive_icon_monochrome: "assets/branding/icon_monochrome.png"   # Android 13 themed icons

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/branding/splash.png                      # logo only, no text (no translation needed)
  color_dark: "#121212"
  image_dark: assets/branding/splash_dark.png
  android_12:
    color: "#FFFFFF"
    image: assets/branding/splash_android12.png          # 960×960, logo inside a 640 circle
    color_dark: "#121212"
    image_dark: assets/branding/splash_android12_dark.png
```

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The hex colours here are build-tool config, not Dart. Keep them equal to the brand colours.

## 6. Android signing

1. Create the upload key once and store it, with its passwords, in the team's password manager.
   **Never commit it.** `.gitignore` covers `*.jks`, `*.keystore` and `key.properties`.

```bash
keytool -genkeypair -v -keystore ~/keys/my_app-upload.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties`. `android/app/build.gradle.kts` reads it when present, and a
   relative `storeFile` is resolved from `android/app/`:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/Users/you/keys/my_app-upload.jks
```

3. Without `key.properties`, release builds fall back to debug keys (for local
   `flutter run --release` only). Check that a release build is signed with the upload key before
   the first upload: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`.
4. Enrol in **Play App Signing** (Google keeps the app signing key; you keep the upload key).
5. Build numbers only go up: `version: 1.0.0+1` in `pubspec.yaml`, and bump `+N` on every upload.

## 7. iOS signing

1. Open `ios/Runner.xcworkspace` → Runner → **Signing & Capabilities**. Select the Team and keep
   "Automatically manage signing" (or use match/manual profiles in CI). The bundle id was set by
   `rename_app.dart`.
2. Add only the capabilities you use: Push Notifications + Background Modes → Remote
   notifications (FCM), Sign in with Apple, Associated Domains (universal links), In-App Purchase.
3. Create the app record in App Store Connect with the same bundle id.
4. `ios/Podfile` targets iOS 13.0. Raise it if a plugin requires more, then run
   `cd ios && pod install`.
5. Archive with `flutter build ipa --release --dart-define-from-file=.env.prod`, then upload with
   Transporter or `xcrun altool` / fastlane.

## 8. Permissions

Keep three places in sync with what the app **actually** uses (full table:
[SERVICES.md#permissions](SERVICES.md#permissions)):

| Place | Template default | Do |
|---|---|---|
| `ios/Podfile` post_install macros | `PERMISSION_CAMERA=1`, `PHOTOS=1`, `MICROPHONE=0`, `NOTIFICATIONS=1`, `LOCATION_WHENINUSE=0` | Set unused ones to `0`. Only enabled permissions are compiled into permission_handler |
| `ios/Runner/Info.plist` usage strings | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` (add `NSMicrophoneUsageDescription` only if you enable the microphone) | **Remove unused strings**. Rewrite the rest to say why in the app's terms, and localize them in `ar.lproj/InfoPlist.strings`. Add `NSLocationWhenInUseUsageDescription` if location is used |
| `android/app/src/main/AndroidManifest.xml` | `INTERNET`, `CAMERA` (+ `uses-feature camera required=false`), `POST_NOTIFICATIONS` | Remove `CAMERA` / `POST_NOTIFICATIONS` if unused. Add `RECORD_AUDIO` (microphone) and `ACCESS_FINE/COARSE_LOCATION` (location) only when used |
| `AppPermission` (`lib/core/services/permission_service.dart`) | camera, photos, location, notifications, microphone | Remove what you don't use so nobody requests a permission the platforms don't declare |

Also trim `LSApplicationQueriesSchemes` (Info.plist) and `<queries>` (manifest) to the schemes that
`UrlService` really opens.

## 9. Flavors

Flavors are `--dart-define-from-file` files. There is no native flavor setup by default.

```bash
cp .env.example .env.staging   # APP_FLAVOR=staging, BASE_URL=https://staging-api.example.com/v1, USE_MOCKS=false
cp .env.example .env.prod      # APP_FLAVOR=prod,    BASE_URL=https://api.example.com/v1,         USE_MOCKS=false

flutter run --dart-define-from-file=.env.staging
flutter build appbundle --release --dart-define-from-file=.env.prod
flutter build ipa --release --dart-define-from-file=.env.prod
```

- All `.env.*` files except `.env.example` are gitignored. In CI they come from secrets (step 11).
- Staging and prod **fail closed**: mocks on or a non-https `BASE_URL` shows the configuration-error
  screen instead of the app.
- If staging and prod must be installed **side by side**, add Gradle `productFlavors` (with an
  `applicationIdSuffix`) and Xcode schemes/configurations. That is native work outside the
  template, so add it only when needed.

## 10. Store listing, privacy and account deletion

- [ ] Privacy policy URL and terms URL (e.g. `https://example.com/privacy`), linked from Settings
      via `UrlService.open(url, inApp: true)`.
- [ ] **Account deletion**: if users can create an account, Apple requires deletion **inside the
      app** (use `showTypedConfirmDialog`), and Google Play requires a **web URL** where deletion
      can be requested.
- [ ] Google Play **Data safety** form and Apple **App Privacy** labels, matching what the app and
      its SDKs (Crashlytics, FCM...) collect.
- [ ] Listing texts in Arabic and English. Screenshots for phone **and tablet**: the app supports
      tablets, and iPad screenshots are required if iPad is supported. Take them with the app in
      each language.
- [ ] Content rating questionnaire, target audience, support email (a team address).
- [ ] Store URLs: put them in `.env.prod` (`ANDROID_STORE_URL`, `IOS_STORE_URL`) and in the
      backend's `/app-config` `store_url`.
- [ ] The backend implements `GET /app-config` (see
      [SERVICES.md#app-config](SERVICES.md#app-config)) and can answer 426/503.

## 11. CI secrets

`.github/workflows/ci.yml` (format, locale keys, translations, analyze, test) needs **no
secrets**. Release jobs restore everything from secrets, encoded as base64 so binary files survive:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i my_app-upload.jks \| tr -d '\n'` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | from step 6 |
| `ENV_PROD` (and `ENV_STAGING`) | the full contents of `.env.prod` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | base64 of the Play service-account JSON (for upload scripts; read with `tool/json_credential.dart`) |
| `GOOGLE_SERVICES_JSON_BASE64`, `GOOGLE_SERVICE_INFO_PLIST_BASE64`, `FIREBASE_OPTIONS_DART_BASE64` | only with Firebase (step 14) |
| App Store Connect API key (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`) | only for automated iOS uploads |

```yaml
# .github/workflows/release-android.yml (excerpt)
- name: Restore signing and env
  env:
    ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
    ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
    ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
    ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
    ENV_PROD: ${{ secrets.ENV_PROD }}
  run: |
    echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/app/upload.jks
    {
      echo "storePassword=$ANDROID_KEYSTORE_PASSWORD"
      echo "keyPassword=$ANDROID_KEY_PASSWORD"
      echo "keyAlias=$ANDROID_KEY_ALIAS"
      echo "storeFile=upload.jks"
    } > android/key.properties
    printf '%s\n' "$ENV_PROD" > .env.prod
- run: flutter build appbundle --release --dart-define-from-file=.env.prod
- name: Check the Play credential (prints metadata only)
  env:
    GOOGLE_SERVICE_ACCOUNT_JSON: ${{ secrets.GOOGLE_SERVICE_ACCOUNT_JSON }}
  run: dart run tool/json_credential.dart GOOGLE_SERVICE_ACCOUNT_JSON
```

Never `cat` or `echo` a secret into the log. Never commit the restored files (they are
gitignored). Rotate any key that was ever committed: petrobe tracked a Play service account in
git.

## 12. Replace the sample feature

The "items" feature (`lib/features/sample_feature/`) is a reference. Keep it until your first real
feature follows the same pattern, then remove it:

1. Create your feature: `/new-feature orders` or `dart run tool/create_feature.dart orders`.
2. Point the first shell branch in `lib/app_router.dart` at your home feature (`AppRoutes.home` is
   `/`), and update the destinations in `lib/shared/screens/home_shell.dart`.
3. Remove `registerItemsFeature` from `lib/main.dart` and the `ItemsRoutes` import from
   `app_router.dart`.
4. Delete `lib/features/sample_feature/`, `test/features/sample_feature/`,
   `assets/mocks/items.json` and the `items.*` keys in both translation files.
5. Run `./tool/gen_locale_keys.sh && dart run tool/check_translations.dart && flutter analyze --fatal-infos && flutter test`.

## 13. Production: mocks off

- [ ] `.env.prod` / `.env.staging`: `USE_MOCKS=false`, an https `BASE_URL`, `VERBOSE_LOGS=false`
      (`AppEnv.validate()` refuses anything else).
- [ ] Every feature's mock routes are registered only `if (getIt.isRegistered<MockInterceptor>())`,
      which is false without mocks.
- [ ] Fixtures in `assets/mocks/` are still bundled. Keep them small and fake (no real data, ever),
      or drop `assets/mocks/` from `pubspec.yaml` once nothing needs them.
- [ ] No dev-only screens or `failNext` toggles reachable in release (guard them with `kDebugMode`).
- [ ] Replace `ConsoleErrorReporter` with a real reporter (step 14), or accept that release errors go
      nowhere.
- [ ] `ApiEndpoints.authRefresh` and `DioTokenRefresher` match the backend, or use
      `NoTokenRefresher`.

## 14. Opt-in modules

Enable only what the app needs. Each one is a recipe, not template code:

| Module | Recipe | Also |
|---|---|---|
| Firebase core | `flutterfire configure` → `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` (all gitignored; restore them in CI) | Initialise in `bootstrap.dart` before `registerCoreDependencies` |
| Crash reporting | [Crashlytics recipe](SERVICES.md#crashlytics-recipe-opt-in) | Gradle plugin + dSYM upload |
| Push | [FCM + local notifications recipe](SERVICES.md#fcm--flutter_local_notifications-recipe-opt-in) | APNs key, `POST_NOTIFICATIONS`, payload `{"type", "id"}` |
| In-app purchases | [IAP recipe](SERVICES.md#in-app-purchases-iap) | Server verification, restore button |
| Maps / location | [Maps recipe](SERVICES.md#maps-and-location) | Keys outside git, location permission (step 8) |

Package versions: [PACKAGES.md#opt-in-packages](PACKAGES.md#opt-in-packages).

## 15. Final verification

```bash
flutter pub get
./tool/gen_locale_keys.sh
dart run tool/check_translations.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build appbundle --release --dart-define-from-file=.env.prod
flutter build ipa --release --dart-define-from-file=.env.prod
```

Then check by hand on devices or emulators:
- [ ] Arabic (RTL) and English, switching languages from Settings without a restart.
- [ ] Light and dark mode. Largest system font size (layouts hold at the 1.3 app cap).
- [ ] Small phone (320 dp wide), tablet, landscape, and a **foldable** emulator folded and unfolded.
- [ ] Airplane mode: offline banner, `NetworkFailure` screens, recovery.
- [ ] `/app-config` with `maintenance: true`, then a `min_build` above the installed build. Both
      gates appear and clear.
- [ ] Session expiry (revoke the token server-side): the app returns to sign-in once, with no loop.
- [ ] A cold-start deep link or notification tap lands on the right screen after the splash.
- [ ] The release build talks to the production `BASE_URL` (check one request in the server logs).
