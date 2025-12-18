#!/usr/bin/env bash
set -u

CLI="deno run --quiet --allow-read src/cli.ts"
TMP_RATES=".tmp-rates.json"
FAILED=0

assert_equals() {
  if [[ "$1" != "$2" ]]; then
    FAILED=1
  fi
}

assert_exit_code() {
  if [[ "$1" -ne "$2" ]]; then
    FAILED=1
  fi
}

cat > "$TMP_RATES" <<EOF
[
  { "fromCurrency": "chf", "toCurrency": "eur", "exchangeRate": 0.9 },
  { "fromCurrency": "eur", "toCurrency": "chf", "exchangeRate": 1.1 },
  { "fromCurrency": "usd", "toCurrency": "chf", "exchangeRate": 0.95 }
]
EOF

out=$($CLI --rates "$TMP_RATES" --from chf --to eur --amount 100)
assert_equals "90" "$out"

out=$($CLI --rates "$TMP_RATES" --from usd --to chf --amount 10)
assert_equals "9.5" "$out"

out=$($CLI --rates "$TMP_RATES" --from eur --to chf --amount 10)
assert_equals "11" "$out"

$CLI --rates "$TMP_RATES" --from xxx --to chf --amount 10 >/dev/null 2>&1
assert_exit_code 1 $?

rm -f "$TMP_RATES"

if [[ "$FAILED" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
