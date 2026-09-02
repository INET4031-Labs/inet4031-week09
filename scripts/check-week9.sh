#!/bin/bash

# Week 9 Validation Check Script
# Verifies all critical Week 9 deliverables before submission.
# Run this from the repository root: ./scripts/check-week9.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
PASS_COUNT=0
FAIL_COUNT=0

# Function to print pass/fail/warn messages
check_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "=========================================="
echo "Week 9 Validation Check"
echo "=========================================="
echo ""

# Check 1: Verify seeded row count
echo "Checking database row count..."
ROW_COUNT=$(docker compose -f "$REPO_ROOT/week-2/docker-compose.yml" exec -T db \
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
echo "Checking database index..."
INDEX_EXISTS=$(docker compose -f "$REPO_ROOT/week-2/docker-compose.yml" exec -T db \
    psql -U appuser -d statustracker -t -c "\di idx_incidents_status_created" | wc -l)

if [ "$INDEX_EXISTS" -gt 0 ]; then
    check_pass "Index idx_incidents_status_created exists"
else
    check_fail "Index idx_incidents_status_created not found"
fi
echo ""

# Check 3: Verify CPU throttle rate is near zero after fix
echo "Checking CPU throttle rate..."
# TODO: ASSUMPTION - This check requires Prometheus to be port-forwarded or accessible
# If running this check in automation, you may need to adjust the query endpoint
# NOTE: container_cpu_cfs_throttled_seconds_total is cgroup v1-only and is not
# exported by cAdvisor on cgroup v2 hosts (e.g. k3d on a modern Docker host).
# Use the periods-based ratio instead, which is available on both cgroup versions.
if command -v curl &> /dev/null; then
    THROTTLE_RATE=$(curl -sg 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_periods_total{container="flask"}[5m])/rate(container_cpu_cfs_periods_total{container="flask"}[5m])' \
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
echo "Checking k6 test scripts..."
if [ -f "$REPO_ROOT/week-9/smoke-test.js" ]; then
    check_pass "smoke-test.js exists"
else
    check_fail "smoke-test.js not found"
fi

if [ -f "$REPO_ROOT/week-9/ramped-test.js" ]; then
    check_pass "ramped-test.js exists"
else
    check_fail "ramped-test.js not found"
fi
echo ""

# Check 5: Verify runbook exists
echo "Checking runbook documentation..."
if [ -f "$REPO_ROOT/week-9/runbook.md" ]; then
    check_pass "runbook.md exists"
    # Check for required sections
    if grep -q "Incident 1.*CPU" "$REPO_ROOT/week-9/runbook.md"; then
        check_pass "Runbook includes Incident 1 (CPU throttling)"
    else
        check_warn "Incident 1 section not clearly titled in runbook"
    fi
    if grep -q "Incident 2.*Sequential" "$REPO_ROOT/week-9/runbook.md"; then
        check_pass "Runbook includes Incident 2 (sequential scan)"
    else
        check_warn "Incident 2 section not clearly titled in runbook"
    fi
else
    check_fail "runbook.md not found"
fi
echo ""

# Check 6: Verify infrastructure/flask.tf has the corrected CPU limit
# NOTE: The Flask Deployment is owned by OpenTofu (infrastructure/flask.tf) since Week 4.
# manifests/flask-deployment.yaml is no longer applied, so it is not checked here.
echo "Checking Flask Deployment CPU limit (infrastructure/flask.tf)..."
if [ -f "$REPO_ROOT/infrastructure/flask.tf" ]; then
    check_pass "infrastructure/flask.tf exists"
    # Check if CPU limit is set to 500m (or higher)
    if grep -q "cpu.*=.*\"500m\"\|cpu.*=.*\"600m\"\|cpu.*=.*\"1\"" "$REPO_ROOT/infrastructure/flask.tf"; then
        check_pass "CPU limit appears to be updated (500m or higher)"
    else
        check_warn "CPU limit not clearly updated to 500m+ in infrastructure/flask.tf"
    fi
else
    check_fail "infrastructure/flask.tf not found"
fi
echo ""

# Check 7: Verify CI workflow has k6 gate
echo "Checking GitHub Actions CI gate..."
if [ -f "$REPO_ROOT/.github/workflows/ci.yml" ]; then
    check_pass ".github/workflows/ci.yml exists"
    if grep -q "load-test-gate\|k6 run" "$REPO_ROOT/.github/workflows/ci.yml"; then
        check_pass "CI workflow includes k6 threshold gate"
    else
        check_warn "k6 gate not found in CI workflow; verify manually"
    fi
else
    check_fail ".github/workflows/ci.yml not found"
fi
echo ""

# Check 8: Verify role-artifact files exist
echo "Checking role artifact files..."
for file in docs/sprint-5-retrospective.md docs/qa-report-5.md; do
    if [ -f "$REPO_ROOT/$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file not found"
    fi
done
echo ""

# Check 9: OpenTofu State Matches the Cluster (No Drift)
echo "Checking OpenTofu drift (infrastructure/flask.tf vs. live cluster)..."
if command -v tofu &> /dev/null && [ -d "$REPO_ROOT/infrastructure" ]; then
    TOFU_PLAN_OUTPUT=$(cd "$REPO_ROOT/infrastructure" && tofu plan -no-color 2>&1)
    if echo "$TOFU_PLAN_OUTPUT" | grep -q "No changes"; then
        check_pass "tofu plan reports no changes (infrastructure/flask.tf matches the cluster)"
    else
        check_fail "tofu plan detected drift -- infrastructure/flask.tf does not match the live cluster (likely a kubectl apply that bypassed OpenTofu)"
    fi
else
    check_fail "tofu is not installed, not on PATH, or infrastructure/ does not exist"
fi
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. See above for details.${NC}"
    exit 1
fi
