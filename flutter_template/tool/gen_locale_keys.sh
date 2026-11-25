#!/usr/bin/env bash
# Regenerates lib/core/localization/generated/locale_keys.g.dart from
# assets/translations/*.json. Run after adding or renaming a translation key.
#
# Source: markspulse / lexa (generated LocaleKeys via easy_localization:generate).
set -euo pipefail
cd "$(dirname "$0")/.."
dart run easy_localization:generate \
  -S assets/translations \
  -f keys \
  -o locale_keys.g.dart \
  -O lib/core/localization/generated
# Keep the generated file in the repo's format (CI checks both).
dart format lib/core/localization/generated/locale_keys.g.dart >/dev/null
