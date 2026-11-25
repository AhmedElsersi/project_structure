# AppName

Flutter app created from `project_structure/flutter_template`.

Arabic first (English second), RTL-first, phones / tablets / foldables, light + dark theme. The
architecture is feature-first clean architecture (data / domain / presentation), and every
repository returns a sealed `Result<T>`.

## Run

```bash
cp .env.example .env            # fill BASE_URL, or leave it empty to use the mock backend
flutter pub get
flutter run --dart-define-from-file=.env
```

With `BASE_URL` empty and the `dev` flavor, all requests are answered by the in-app mock backend
(`lib/core/network/mock/` + `assets/mocks/`). The sample feature works offline.

## Everyday commands

```bash
./tool/gen_locale_keys.sh                      # after editing assets/translations/*.json
dart run tool/check_translations.dart          # ar/en parity, placeholders, plurals
dart run tool/create_feature.dart orders [--use-cases]
dart format lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

## Where things are

| Path | What |
|---|---|
| `lib/main.dart`, `lib/bootstrap.dart` | entry + startup (env check, DI, error hooks, session restore) |
| `lib/app.dart`, `lib/app_router.dart` | MaterialApp (theme, l10n, damped text scale, app gate) + go_router |
| `lib/core/` | infrastructure: config, di, network, errors/result, state bases, storage, session, router, theme, responsive, localization, services, utils |
| `lib/shared/widgets/`, `lib/shared/screens/` | generic widgets and app-level screens |
| `lib/features/sample_feature/` | the pattern to copy (replace it with your features) |
| `test/policy/` | convention checks (RTL, colours, strings, layering, deprecated APIs) |
| `tool/` | feature scaffolder, renamer, translation checker, JSON-credential loader |

Rules for this codebase are in `CLAUDE.md`. The full docs (architecture, services, widgets,
conventions, new-project checklist) are in `project_structure/docs/`.
