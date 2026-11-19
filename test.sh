#!/usr/bin/env bash
# test_api.sh — full API test suite using curl
# Usage: bash test_api.sh [BASE_URL]
# Default: http://localhost:3000

set -e

BASE=${1:-http://localhost:3000}
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Helper: extract value from JSON (jq-like path)
json_get() {
  local json="$1"
  local path="$2"
  echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
path = '$path'.lstrip('.')
for key in path.split('.'):
    if key == '':
        continue
    if key.isdigit():
        data = data[int(key)]
    else:
        data = data[key]
print(data)
" 2>/dev/null || echo ""
}

check() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $name"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}✗${NC} $name (expected: $expected, got: $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> Testing API at $BASE"
echo

# 1. Health check
echo "--- 1. Health check ---"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BASE/books)
check "GET /books → 200" "200" "$STATUS"

# 2. Create book
echo
echo "--- 2. Create book ---"
BOOK=$(curl -s -X POST $BASE/books \
  -H "Content-Type: application/json" \
  -d '{"book":{"title":"Test Book","author":"Author"}}')
SERIAL=$(json_get "$BOOK" "serial_number")
check "POST /books → serial_number present" "true" "$([ -n "$SERIAL" ] && [ "$SERIAL" != "null" ] && echo true || echo false)"

# 3. Books list
echo
echo "--- 3. Books list ---"
LIST=$(curl -s $BASE/books)
check "GET /books → data array" "true" "$(echo "$LIST" | python3 -c 'import sys,json; print(json.dumps(isinstance(json.load(sys.stdin)["data"], list)))')"

META=$(json_get "$LIST" "meta.total_count")
check "GET /books → meta.total_count > 0" "true" "$([ -n "$META" ] && [ "$META" -gt 0 ] && echo true || echo false)"

# 4. Book details
echo
echo "--- 4. Book details ---"
DETAIL=$(curl -s $BASE/books/$SERIAL)
check "GET /books/:id → serial_number" "$SERIAL" "$(json_get "$DETAIL" "serial_number")"
check "GET /books/:id → status available" "available" "$(json_get "$DETAIL" "status")"

# 5. Borrow book
echo
echo "--- 5. Borrow book ---"
LOAN=$(curl -s -X POST $BASE/books/$SERIAL/loans \
  -H "Content-Type: application/json" \
  -d '{"card_number":"000001"}')
LOAN_ID=$(json_get "$LOAN" "id")
check "POST /books/:id/loans → loan id present" "true" "$([ -n "$LOAN_ID" ] && [ "$LOAN_ID" != "null" ] && echo true || echo false)"

if [ -n "$LOAN_ID" ]; then
  # 6. Status after borrow
  echo
  echo "--- 6. Status after borrow ---"
  STATUS_AFTER=$(json_get "$(curl -s $BASE/books/$SERIAL)" "status")
  check "GET /books/:id → status borrowed" "borrowed" "$STATUS_AFTER"

  # 7. Borrow again (conflict)
  echo
  echo "--- 7. Borrow again (409) ---"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/books/$SERIAL/loans \
    -H "Content-Type: application/json" \
    -d '{"card_number":"000001"}')
  check "POST /books/:id/loans (already borrowed) → 409" "409" "$STATUS"

  # 8. Return book
  echo
  echo "--- 8. Return book ---"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH $BASE/loans/$LOAN_ID/return)
  check "PATCH /loans/:id/return → 200" "200" "$STATUS"

  # 9. Status after return
  echo
  echo "--- 9. Status after return ---"
  STATUS_AFTER=$(json_get "$(curl -s $BASE/books/$SERIAL)" "status")
  check "GET /books/:id → status available" "available" "$STATUS_AFTER"

  # 10. Return again (conflict)
  echo
  echo "--- 10. Return again (409) ---"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH $BASE/loans/$LOAN_ID/return)
  check "PATCH /loans/:id/return (already returned) → 409" "409" "$STATUS"
fi

# 11. Reject manual serial_number
echo
echo "--- 11. Reject manual serial_number (400) ---"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/books \
  -H "Content-Type: application/json" \
  -d '{"book":{"serial_number":"999999","title":"X","author":"Y"}}')
check "POST /books (with serial_number) → 400" "400" "$STATUS"

# 12. Pagination
echo
echo "--- 12. Pagination ---"
PER_PAGE=$(json_get "$(curl -s "$BASE/books?page=1&per_page=2")" "meta.per_page")
check "GET /books?page=1&per_page=2 → per_page" "2" "$PER_PAGE"

BIG_PER_PAGE=$(json_get "$(curl -s "$BASE/books?per_page=9999")" "meta.per_page")
check "GET /books?per_page=9999 → max 100" "100" "$BIG_PER_PAGE"

EMPTY_COUNT=$(curl -s "$BASE/books?page=9999" | python3 -c 'import sys,json; print(len(json.load(sys.stdin)["data"]))')
check "GET /books?page=9999 → empty list" "0" "$EMPTY_COUNT"

# 13. Sorting
echo
echo "--- 13. Sorting ---"
SORTED=$(curl -s "$BASE/books?sort=title&order=asc" | python3 -c '
import sys, json
titles = [b["title"] for b in json.load(sys.stdin)["data"]]
print("true" if titles == sorted(titles) else "false")
')
check "GET /books?sort=title&order=asc → sorted" "true" "$SORTED"

# 14. Filtering
echo
echo "--- 14. Filtering ---"
AVAILABLE=$(curl -s "$BASE/books?status=available" | python3 -c '
import sys, json
statuses = [b["status"] for b in json.load(sys.stdin)["data"]]
print("true" if all(s == "available" for s in statuses) else "false")
')
check "GET /books?status=available → all available" "true" "$AVAILABLE"

# 15. Error cases
echo
echo "--- 15. Error cases ---"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BASE/books/999999)
check "GET /books/999999 → 404" "404" "$STATUS"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE/books/$SERIAL/loans \
  -H "Content-Type: application/json" \
  -d '{"card_number":"999999"}')
check "POST /books/:id/loans (unknown reader) → 404" "404" "$STATUS"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH $BASE/loans/999999/return)
check "PATCH /loans/999999/return → 404" "404" "$STATUS"

# 16. Deletion
echo
echo "--- 16. Deletion ---"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $BASE/books/$SERIAL)
check "DELETE /books/:id → 204" "204" "$STATUS"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BASE/books/$SERIAL)
check "GET /books/:id (deleted) → 404" "404" "$STATUS"

# Summary
echo
echo "========================================"
echo -e "Result: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "========================================"

if [ $FAIL -gt 0 ]; then
  exit 1
fi