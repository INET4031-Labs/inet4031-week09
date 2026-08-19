## Week 9: End-to-End Performance Investigation

**Sprint 5 Kickoff | Synchronous**

> **Pre-check required.** Week 9's CPU throttling diagnosis depends on Prometheus scraping `container_cpu_cfs_throttled_seconds_total`, configured in Week 5. Run the pre-check in Part 0 before proceeding. If the metric is unavailable, follow the inline fix before continuing.

### Overview

In this lab, your team loads the incident tracker with tens of thousands of synthetic records, then investigates two performance problems: a database-layer bottleneck exposed by query patterns at scale and an infrastructure-layer bottleneck caused by an intentionally low CPU limit. You will use k6 for load testing, Prometheus and Grafana for USE method diagnosis, `pg_stat_statements` and `EXPLAIN (ANALYZE, BUFFERS)` for database-layer diagnosis, and `rate(container_cpu_cfs_throttled_seconds_total[5m])` for infrastructure-layer diagnosis. The lab closes with a k6 threshold gate added to GitHub Actions. After completing this lab, you will have a performance runbook documenting both issues with measured before/after improvements and a regression gate in CI.

### Learning Objectives

- Use the USE method to identify which resource saturates first under load
- Diagnose a missing database index using `pg_stat_statements` and `EXPLAIN (ANALYZE, BUFFERS)`
- Diagnose CPU throttling using `rate(container_cpu_cfs_throttled_seconds_total[5m])`
- Add a k6 threshold gate to GitHub Actions as a permanent regression check

### Prerequisites

- Week 5 complete: Prometheus deployed with kubelet scraping verified (mandatory pre-check below)
- Week 8 complete: application has data in the database
- k6 installed from Week 5

---

### Part 0: Pre-Check -- Verify Week 5 Metric Is Available

**Step 0a.** Port-forward Prometheus.

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
```

**Step 0b.** Query for the CPU throttling metric.

```bash
curl -s 'http://localhost:9090/api/v1/query?query=container_cpu_cfs_throttled_seconds_total' \
  | python3 -c "import json,sys; d=json.load(sys.stdin); r=d['data']['result']; print(f'PASS -- {len(r)} series') if r else print('FAIL -- no data')"
```

If `PASS`: proceed to Sprint Review.

If `FAIL`: Prometheus is not scraping kubelet. Fix before continuing:

1. Check kubelet ServiceMonitor: `kubectl get servicemonitor -n monitoring`
2. If missing, re-upgrade: `helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring -f week-5/prometheus-values.yaml`
3. Wait two minutes, re-run Step 0b. If still failing, raise with your TA.

---

### Sprint Review: Sprint 4

**Step 1.** Open the sprint board. Move all Sprint 4 items to Done.

**Step 2.** Sprint retrospective in Google Doc under "Sprint 4 Close."

**Step 3.** Environment checkpoint.

```bash
k3d cluster list
kubectl get pods
kubectl get pods -n monitoring
git log --oneline -5
```

**Step 4.** Assign Sprint 5 roles, open Sprint 5 issues.

---

### Part 1: Load the Database

**Step 5.** Run the shared seeder script provided by the professor.

```bash
python3 /path/to/seeder.py \
  --host localhost \
  --port 5432 \
  --database statustracker \
  --user appuser \
  --rows 50000
```

**Step 6.** Verify the row count.

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker -c "SELECT COUNT(*) FROM incidents;"
```

Expected: approximately 50,000 rows.

---

### Part 2: Baseline Load Test

**Step 7.** Create `week-9/smoke-test.js`.

```javascript
import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 5,
  duration: '1m',
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    'http_req_failed': ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('http://localhost:8080/incidents');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

**Step 8.** Run the smoke test and record the baseline.

```bash
k6 run week-9/smoke-test.js
```

Record: RPS, P50, P95, error rate. Add to Google Doc under "Week 9 Baseline."

---

### Part 3: Ramped Load Test and USE Method Diagnosis

**Step 9.** Apply the intentionally throttled CPU limit Deployment provided by the professor (CPU limit set to `100m`).

```bash
kubectl apply -f /path/to/flask-throttled-deployment.yaml
```

**Step 10.** Create `week-9/ramped-test.js`.

```javascript
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '3m', target: 50 },
    { duration: '1m', target: 0 },
  ],
};

export default function () {
  http.get('http://localhost:8080/incidents');
  sleep(0.5);
}
```

**Step 11.** Run the ramped test while watching Grafana.

```bash
k6 run week-9/ramped-test.js &
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
```

Watch the Flask USE Dashboard while the test runs.

**Step 12.** Query CPU throttling in Prometheus.

```bash
curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_seconds_total%7Bcontainer%3D"flask"%7D%5B5m%5D)' \
  | python3 -m json.tool
```

Record the throttle rate value. A value above 0 confirms throttling.

**Step 13.** Diagnose the database bottleneck.

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker \
  -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker \
  -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 5;"
```

Find the slowest query. Run `EXPLAIN (ANALYZE, BUFFERS)` against it.

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker \
  -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM incidents WHERE status = 'open' ORDER BY created_at DESC LIMIT 10;"
```

Look for `Seq Scan` in the output.

---

### Part 4: Fix Both Issues and Measure Improvement

**Step 14.** Fix the database issue. Add an index.

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker \
  -c "CREATE INDEX CONCURRENTLY idx_incidents_status_created ON incidents(status, created_at DESC);"
```

Run `EXPLAIN (ANALYZE, BUFFERS)` again. Confirm `Index Scan` replaces `Seq Scan`.

**Step 15.** Fix the infrastructure issue. Update the Flask Deployment CPU limit from `100m` to `500m` in `manifests/flask-deployment.yaml`.

```bash
kubectl apply -f manifests/flask-deployment.yaml
```

**Step 16.** Re-run the ramped test.

```bash
k6 run week-9/ramped-test.js
```

Record: RPS, P50, P95, error rate. Compare to the Week 9 baseline.

**Step 17.** Query CPU throttling again.

```bash
curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_seconds_total%7Bcontainer%3D"flask"%7D%5B5m%5D)' \
  | python3 -m json.tool
```

The throttle rate should be near zero.

---

### Part 5: Add k6 Threshold Gate to CI

**Step 18.** Update `.github/workflows/ci.yml` with a k6 threshold check job.

```yaml
  load-test-gate:
    runs-on: ubuntu-latest
    needs: build-and-push

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install k6
        run: |
          curl https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz -Lo /tmp/k6.tar.gz
          tar -xzf /tmp/k6.tar.gz -C /tmp
          sudo mv /tmp/k6-v0.47.0-linux-amd64/k6 /usr/local/bin/k6

      - name: Run k6 smoke test threshold gate
        run: k6 run week-9/smoke-test.js
```

The `p(95)<500` threshold in `smoke-test.js` causes this job to fail if P95 exceeds 500ms.

**Step 19.** Commit all changes.

```bash
git add week-9/ manifests/ .github/
git commit -m "feat: load tests, fix CPU throttling and missing index, add k6 CI gate"
git push origin main
```

---

### Runbook: Write and Commit

Create `week-9/runbook.md` using the same structure as the Week 8 runbook.

```markdown
**Incident 1:** CPU throttling under load

**Symptom:** P95 response time exceeds 500ms during ramped load test. Grafana CPU saturation panel shows non-zero throttle rate.

**Root Cause:** Flask Deployment CPU limit set to 100m. At 50 VUs, the container requests more CPU than the limit allows.

**Fix:**
1. Confirm throttling: rate(container_cpu_cfs_throttled_seconds_total{container="flask"}[5m]) > 0
2. Identify the limit: kubectl get deployment flask -o yaml | grep -A5 resources
3. Update cpu limit from 100m to 500m in manifests/flask-deployment.yaml
4. Apply: kubectl apply -f manifests/flask-deployment.yaml
5. Re-run load test and confirm throttle rate drops to near zero

**Measured Before/After vs. Stated Target:**
- P95 before fix: [your value]ms
- P95 after fix: [your value]ms
- CPU throttle rate before: [your value]
- CPU throttle rate after: [your value]
- Target: P95 < 500ms

---

**Incident 2:** Sequential scan on incidents table

**Symptom:** pg_stat_statements shows high mean_exec_time. EXPLAIN ANALYZE shows Seq Scan on 50,000 rows.

**Root Cause:** No index on (status, created_at). Full table scan required for every filtered/sorted query.

**Fix:**
1. Confirm: EXPLAIN (ANALYZE, BUFFERS) shows "Seq Scan on incidents"
2. Create index: CREATE INDEX CONCURRENTLY idx_incidents_status_created ON incidents(status, created_at DESC)
3. Verify: re-run EXPLAIN ANALYZE, confirm "Index Scan" appears

**Measured Before/After vs. Stated Target:**
- Mean query time before index: [your value]ms
- Mean query time after index: [your value]ms
- P95 before: [your value]ms
- P95 after: [your value]ms
- Target: P95 < 500ms
```

---

### Storage Check

```bash
df -h
docker system df
kubectl top pods
```

Record in Google Doc under "Week 9 Storage Check."

---

### Validation Checks

#### Validation Check: Seeded Row Count

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker -c "SELECT COUNT(*) FROM incidents;"
```

Expected: approximately 50,000 rows.

#### Validation Check: CPU Throttle Rate Near Zero After Fix

```bash
curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_seconds_total{container="flask"}[5m])' \
  | python3 -c "import json,sys; d=json.load(sys.stdin); v=float(d['data']['result'][0]['value'][1]) if d['data']['result'] else 0; print('PASS' if v < 0.01 else f'FAIL -- throttle rate {v}')"
```

Expected: `PASS`

#### Validation Check: Index Exists

```bash
docker compose -f week-2/docker-compose.yml exec db \
  psql -U appuser -d statustracker \
  -c "\di idx_incidents_status_created"
```

Expected: one row listing `idx_incidents_status_created`.

#### Validation Check: k6 Smoke Test Passes Threshold

```bash
k6 run week-9/smoke-test.js
```

Expected: all thresholds passing in k6 output.

#### Validation Check: Check Script Passes

```bash
./scripts/check-week9.sh
```

---

### Deliverables

- `week-9/smoke-test.js` and `week-9/ramped-test.js` committed
- `week-9/runbook.md` committed using the two-incident format
- `manifests/flask-deployment.yaml` updated with corrected CPU limit
- `.github/workflows/ci.yml` updated with k6 threshold gate
- Google Doc updated with baseline vs. post-fix comparison numbers
- `./scripts/check-week9.sh` runs clean

**Screenshot requirements:**

- **Screenshot 1:** Prometheus query showing non-zero throttle rate before fix
- **Screenshot 2:** `EXPLAIN ANALYZE` output showing Seq Scan (before index)
- **Screenshot 3:** `EXPLAIN ANALYZE` output showing Index Scan (after index)
- **Screenshot 4:** k6 output after fixes showing thresholds passing
- **Screenshot 5:** `./scripts/check-week9.sh` passing

---

### Reflection Questions (Answer in Google Doc)

1. You found two performance problems: one at the database layer and one at the infrastructure layer. Which caused more impact to P95 response time? How do you know?
2. The k6 threshold gate fails CI if P95 exceeds 500ms. Name a scenario where this threshold would produce a false positive (fails CI even though the application is actually fine). How would a team tune the threshold to reduce false positives?
3. You used `pg_stat_statements` to find slow queries. This extension has overhead because it records every query. Under what circumstances would you disable it in production?
4. After adding the index, reads became index scans instead of sequential scans. Indexes consume disk space and slow down write operations. How would you decide whether the read improvement justifies the write overhead?
5. (Extend) The CPU limit was set to 100m in the throttled manifest. In a real team, how would you prevent an under-resourced Deployment from being merged to main? What process or automated check would catch it?

---

---

