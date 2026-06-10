#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# check-keys.sh — compare translation keys between .lang files.
#
# Every .lang file must expose exactly the same set of "Section/Key" entries as
# the reference file (en.lang by default). The script reports, for each other
# language, the keys that are MISSING (present in the reference, absent here)
# and the keys that are EXTRA (present here, absent from the reference).
#
# Usage:
#   scripts/check-keys.sh [LOCALE_DIR] [REFERENCE_CODE]
#
# Examples:
#   scripts/check-keys.sh                 # locale/ , reference en
#   scripts/check-keys.sh locale fr       # use fr.lang as the reference
#
# Exit code: 0 if every file matches the reference, 1 otherwise.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCALE_DIR="${1:-$SCRIPT_DIR/../locale}"
REF_CODE="${2:-en}"
REF_FILE="$LOCALE_DIR/$REF_CODE.lang"

if [ ! -f "$REF_FILE" ]; then
  echo "error: reference file not found: $REF_FILE" >&2
  exit 2
fi

# Extract a sorted, unique list of "Section/Key" from a .lang file.
# Skips comments (;), blank lines and section headers; the [Language] header
# section is ignored because its keys are metadata, not translatable strings.
extract_keys() {
  awk '
    /^[[:space:]]*;/   { next }                         # comment
    /^[[:space:]]*$/   { next }                         # blank line
    /^[[:space:]]*\[/  {                                # [Section] header
      line = $0
      sub(/^[[:space:]]*\[/, "", line)
      sub(/\].*$/, "", line)
      section = line
      next
    }
    /=/ {
      key = $0
      sub(/=.*$/, "", key)                              # strip value
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)      # trim
      if (section != "Language" && key != "")
        print section "/" key
    }
  ' "$1" | LC_ALL=C sort -u
}

ref_keys="$(extract_keys "$REF_FILE")"
status=0

echo "Reference: $REF_CODE.lang ($(printf '%s\n' "$ref_keys" | grep -c . ) keys)"
echo

for file in "$LOCALE_DIR"/*.lang; do
  code="$(basename "$file" .lang)"
  [ "$code" = "$REF_CODE" ] && continue

  other_keys="$(extract_keys "$file")"

  missing="$(comm -23 <(printf '%s\n' "$ref_keys") <(printf '%s\n' "$other_keys"))"
  extra="$(comm -13 <(printf '%s\n' "$ref_keys") <(printf '%s\n' "$other_keys"))"

  if [ -z "$missing" ] && [ -z "$extra" ]; then
    echo "OK   $code.lang — keys match $REF_CODE.lang"
  else
    status=1
    echo "FAIL $code.lang"
    if [ -n "$missing" ]; then
      echo "  Missing (in $REF_CODE, not in $code):"
      printf '%s\n' "$missing" | sed 's/^/    - /'
    fi
    if [ -n "$extra" ]; then
      echo "  Extra (in $code, not in $REF_CODE):"
      printf '%s\n' "$extra" | sed 's/^/    + /'
    fi
  fi
done

echo
if [ "$status" -eq 0 ]; then
  echo "All language files are in sync."
else
  echo "Some language files are out of sync (see above)."
fi
exit "$status"
