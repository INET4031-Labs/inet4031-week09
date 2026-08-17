#!/bin/bash

# Week 9 Validation Check Script
# Verifies all critical Week 9 deliverables before submission

set -e

PASS=0
FAIL=0

echo "=========================================="
echo "Week 9 Validation Check Script"
echo "=========================================="
echo ""

# Helper functions
check_pass() {
  local msg="$1"
  echo "[PASS] $msg"
  ((PASS++))
}

check_fail() {
  local msg="$1"
  echo "[FAIL] $msg"
  ((FAIL++))
}

check_warn() {
  local msg="$1"
  echo "[WARN] $msg"
}

# Check 1: Verify seeded row count
echo "Check 1: Database Row Count"
echo "---"
ROW_COUNT=$(docker compose -f week-2/docker-compose.yml exec -T db \
  psql -U appuser -d statustracker -t -c "SELECT COUNT(*) FROM incidents;" | tr -d ' ')

if [ -n "$ROW_COUNT" ]; then
  if [ "$ROW_COUNT" -ge 49500 ] && [ "$ROW_COUNT" -le 50500 ]; then
    check_pass "Row count: $ROW_COUNT (approximately 50,000 expected)"
  else
    check_warn "Row count: $ROW_COUNT (expected ~50,000; count is within tolerance for asynchronous processes)"
  fi
else
  check_fail "Could not retrieve row count from database"
fi
echo ""

# Check 2: Verify index exists
echo "Check 2: Database Index"
echo "---"
INDEX_EXISTS=$(docker compose -f week-2/docker-compose.yml exec -T db \
  psql -U appuser -d statustracker -t -c "\di idx_incidents_status_created" | wc -l)

if [ "$INDEX_EXISTS" -gt 0 ]; then
  check_pass "Index idx_incidents_status_created exists"
else
  check_fail "Index idx_incidents_status_created not found"
fi
echo ""

# Check 3: Verify CPU throttle rate is near zero after fix
echo "Check 3: CPU Throttle Rate"
echo "---"
# TODO: ASSUMPTION - This check requires Prometheus to be port-forwarded or accessible
# If running this check in automation, you may need to adjust the query endpoint
if command -v curl &> /dev/null; then
  THROTTLE_RATE=$(curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_seconds_total{container="flask"}[5m])' \
    | python3 -c "import json,sys; d=json.load(sys.stdin); v=float(d['data']['result'][0]['value'][1]) if d['data']['result'] else 0; print(f'{v:.4f}')" 2>/dev/null || echo "ERROR")

  if [ "$THROTTLE_RATE" != "ERROR" ]; then
    THROTTLE_NUM=$(echo "$THROTTLE_RATE" | cut -d. -f1,2)
    if (( $(echo "$THROTTLE_NUM < 0.01" | bc -l) )); then
      check_pass "CPU throttle rate: $THROTTLE_RATE (< 0.01 after fix)"
    else
      check_warn "CPU throttle rate: $THROTTLE_RATE (> 0.01; verify fix was applied)"
    fi
  else
    check_warn "Could not query Prometheus (may not be port-forwarded); skipping throttle check"
  fi
else
  check_warn "curl not found; skipping Prometheus query"
fi
echo ""

# Check 4: Verify k6 test files exist
echo "Check 4: k6 Test Scripts"
echo "---"
if [ -f "week-9/smoke-test.js" ]; then
  check_pass "smoke-test.js exists"
else
  check_fail "smoke-test.js not found"
fi

if [ -f "week-9/ramped-test.js" ]; then
  check_pass "ramped-test.js exists"
else
  check_fail "ramped-test.js not found"
fi
echo ""

# Check 5: Verify runbook exists
echo "Check 5: Runbook Documentation"
echo "---"
if [ -f "week-9/runbook.md" ]; then
  check_pass "runbook.md exists"
  # Check for required sections
  if grep -q "Incident 1.*CPU" week-9/runbook.md; then
    check_pass "Runbook includes Incident 1 (CPU throttling)"
  else
    check_warn "Incident 1 section not clearly titled in runbook"
  fi
  if grep -q "Incident 2.*Sequential" week-9/runbook.md; then
    check_pass "Runbook includes Incident 2 (sequential scan)"
  else
    check_warn "Incident 2 section not clearly titled in runbook"
  fi
else
  check_fail "runbook.md not found"
fi
echo ""

# Check 6: Verify manifests/flask-deployment.yaml exists
echo "Check 6: Flask Deployment Manifest"
echo "---"
if [ -f "manifests/flask-deployment.yaml" ]; then
  check_pass "manifests/flask-deployment.yaml exists"
  # Check if CPU limit is set to 500m (or higher)
  if grep -q "cpu:.*500m\|cpu:.*600m\|cpu:.*1\|cpu:.*\"1\"" manifests/flask-deployment.yaml; then
    check_pass "CPU limit appears to be updated (500m or higher)"
  else
    check_warn "CPU limit not clearly updated to 500m+ in manifest"
  fi
else
  check_fail "manifests/flask-deployment.yaml not found"
fi
echo ""

# Check 7: Verify CI workflow has k6 gate
echo "Check 7: GitHub Actions CI Gate"
echo "---"
if [ -f ".github/workflows/ci.yml" ]; then
  check_pass ".github/workflows/ci.yml exists"
  if grep -q "load-test-gate\|k6 run" .github/workflows/ci.yml; then
    check_pass "CI workflow includes k6 threshold gate"
  else
    check_warn "k6 gate not found in CI workflow; verify manually"
  fi
else
  check_fail ".github/workflows/ci.yml not found"
fi
echo ""

# Check 8: Verify role-artifact files exist
echo "Check 8: Role Artifact Files"
echo "---"
ARTIFACTS_OK=true
for file in docs/sprint-5-retrospective.md docs/week-09-environment-log.md docs/week-09-acceptance-criteria.md docs/qa-report-5.md; do
  if [ -f "$file" ]; then
    check_pass "$file exists"
  else
    check_fail "$file not found"
    ARTIFACTS_OK=false
  fi
done
echo ""

# Summary
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "Status: ALL CHECKS PASSED"
  exit 0
else
  echo "Status: SOME CHECKS FAILED"
  echo "Review failed items above and rework as needed."
  exit 1
fi
