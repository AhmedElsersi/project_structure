---
description: Create a new Flutter app from project_structure/flutter_template (copy, rename, env, branding, git init, verify, checklist)
argument-hint: <target_folder> <dart_package_name> "<Display Name>" <application.id>
---

Create a new app from the template with: **$ARGUMENTS**

Expected arguments, in order: `<target_folder> <dart_package_name> "<Display Name>" <application.id>`.
Example: `../shop_app shop_app "Shop" com.example.shop`.

The template is `flutter_template/` inside the `project_structure` folder this command lives in
(this repository). If you can't find it, ask for its path. **Never modify `flutter_template/`
itself.** All edits happen in the target folder.

## 0. Validate the inputs (ask if anything is missing or invalid)

- `target_folder`: must not exist, or must be empty. Resolve it relative to the current directory
  and print the absolute path you will use.
- `dart_package_name`: `snake_case`, starts with a letter, not a Dart reserved word (`shop_app`).
- `Display Name`: the user-facing English name (quoted when it has spaces). Also ask for the
  **Arabic** name, which goes into `ar.json` `app.name`.
- `application.id`: reverse-DNS, lowercase, at least two segments (`com.company.app`). Warn that it
  can't change after publishing.
- Also ask (with defaults the user can accept): `BASE_URL` (empty = mock backend), the brand
  primary colour (hex), the font family (Arabic + Latin, or none), and whether icon/splash source
  images exist.

## 1. Copy the template

```bash
rsync -a \
  --exclude build --exclude .dart_tool --exclude .env --exclude 'ios/Pods' \
  --exclude .idea --exclude '*.iml' --exclude .flutter-plugins-dependencies \
  --exclude 'android/local.properties' --exclude 'android/.gradle' \
  --exclude 'ios/Flutter/Generated.xcconfig' --exclude 'ios/Flutter/ephemeral' \
  --exclude 'ios/Flutter/flutter_export_environment.sh' --exclude .DS_Store \
  <project_structure>/flutter_template/ <target_folder>/
```

Verify that no `.env`, keystore or credential was copied:
`ls -a <target_folder> && git -C <target_folder> status 2>/dev/null` (there is no repo yet).

## 2. Rename

From `<target_folder>`:

```bash
dart run tool/rename_app.dart --package <dart_package_name> --name "<Display Name>" --id <application.id> --dry-run
dart run tool/rename_app.dart --package <dart_package_name> --name "<Display Name>" --id <application.id>
```

Review the dry run before applying it. Afterwards, check that no `app_template` or `com.example.app`
references remain where they matter:
`grep -rn "app_template\|com.example.app" lib test tool android ios pubspec.yaml` (placeholder store
URLs in `.env.example` are fine).

## 3. Bring the rules and docs

- Copy `<project_structure>/CLAUDE.md` to `<target_folder>/CLAUDE.md` unchanged. It is the rule
  set for this app.
- Copy `<project_structure>/docs/` to `<target_folder>/docs/` **without** `docs/_analysis/`, so the
  links in CLAUDE.md resolve.
- Replace the template's default `README.md` with a short one: app name, how to run
  (`cp .env.example .env`, `flutter run --dart-define-from-file=.env`), and links to `CLAUDE.md` and
  `docs/`.

## 4. Environment

```bash
cp .env.example .env
```

Set `APP_FLAVOR=dev` and `BASE_URL` (empty keeps `USE_MOCKS` on). Leave the store URLs as
placeholders until the store records exist. Never put secrets in `.env`. Explain the
`.env.staging` / `.env.prod` convention from `docs/NEW_PROJECT_CHECKLIST.md` (step 9), but don't
create them with made-up values.

## 5. Branding

- `lib/core/theme/app_colors.dart`: set `AppColors.brandSeed` to the brand colour
  (`Color(0xFFRRGGBB)`, the only file where colour literals are allowed).
- Font (if given): add the files and their licence under `assets/fonts/`, add a `fonts:` entry in
  `pubspec.yaml`, and set `AppTypography.fontFamily` in `lib/core/theme/app_typography.dart`.
- `assets/translations/ar.json` → `app.name` = the Arabic name. `en.json` → `app.name` = the
  display name (rename_app sets it only while it is the placeholder; check it).
- Icons and splash: if source images exist, add `flutter_launcher_icons` / `flutter_native_splash`
  as **dev_dependencies** with the config from `docs/NEW_PROJECT_CHECKLIST.md` step 5, then run
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`. Otherwise list it
  as pending. Replace the `FlutterLogo` in `lib/shared/screens/splash_screen.dart` only when a
  logo asset exists.
- Run `flutter test test/core/theme/` after changing colours (contrast tests).

## 6. Git

```bash
git init
git status --short | head -50     # confirm .env, build/, keys are NOT listed
```

Do **not** create a commit unless the user asks. Suggest `main` + `dev` branches.

## 7. Install and verify

```bash
flutter pub get
./tool/gen_locale_keys.sh
dart run tool/check_translations.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Everything must pass before you continue. If something fails because of the rename or branding,
fix it in the target. If it fails in untouched template code, report it and don't hack around it.

## 8. Walk the checklist

Open `docs/NEW_PROJECT_CHECKLIST.md` and go through all 15 steps. For each one, report **done**
(what you did), **pending — needs the user** (signing keys, store accounts, Firebase, privacy URLs,
CI secrets), or **not applicable**. Pay special attention to:

- step 8: trim the Podfile permission macros, Info.plist usage strings and AndroidManifest
  permissions to what the app will use (ask if unknown);
- step 12: keep the sample feature until the first real feature exists, then remove it with
  `/new-feature` + the removal steps;
- step 14: list the opt-in modules (Crashlytics, FCM, IAP, maps) and ask which ones the app needs.
  Don't add them without confirmation.

Finish with a short summary: the target path, package, display names (en/ar), application id,
the commands to run the app, and the pending checklist items.
