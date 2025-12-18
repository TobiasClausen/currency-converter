#!/usr/bin/env bash
set -u

SERVER_CMD="deno run --quiet --allow-net src/server.ts"
BASE_URL="http://localhost:8000"
FAILED=0

assert_equals() {
  if [[ "$1" != "$2" ]]; then
    FAILED=1
  fi
}

assert_status() {
  if [[ "$1" -ne "$2" ]]; then
    FAILED=1
  fi
}

$SERVER_CMD >/dev/null 2>&1 &
SERVER_PID=$!

sleep 1

status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/rate/chf/eur/0.9")
assert_status 200 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/rate/chf/eur")
assert_status 200 "$status"

rate=$(curl -s "$BASE_URL/rate/chf/eur" | jq -r '.rate')
assert_equals "0.9" "$rate"

status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/rate/xxx/yyy")
assert_status 404 "$status"

value=$(curl -s "$BASE_URL/conversion/chf/eur/100" | jq -r '.value')
assert_equals "90" "$value"

status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/rate/eur/chf/1.1")
assert_status 200 "$status"

value=$(curl -s "$BASE_URL/conversion/eur/chf/10" | jq -r '.value')
assert_equals "11" "$value"

status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/rate/chf/eur")
assert_status 200 "$status"

status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/conversion/chf/eur/10")
assert_status 404 "$status"

kill "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null || true

if [[ "$FAILED" -eq 0 ]]; then
  exit 0
else
  exit 1
fi

