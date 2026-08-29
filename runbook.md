# Week 9 Performance Runbook

## Incident 1: CPU Throttling Under Load

**Symptom**
P95 response time exceeds 500ms during ramped load test. Grafana CPU saturation panel shows non-zero throttle rate.

**Root Cause**
Flask Deployment CPU limit set to 100m. At 50 VUs, the container requests more CPU than the limit allows, causing the kernel to throttle the process.

**Fix**

1. Confirm throttling is occurring:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_cfs_throttled_seconds_total{container="flask"}[5m])' \
     | python3 -m json.tool
   ```
   A value above 0 confirms throttling is active.

2. Identify the current CPU limit:
   ```bash
   kubectl get deployment flask -o yaml | grep -A5 resources
   ```

3. Confirm/set the CPU limit to 500m in `infrastructure/flask.tf` (`kubernetes_deployment.flask` resource).

4. Apply the updated deployment:
   ```bash
   cd infrastructure && tofu plan && tofu apply
   ```

5. Re-run the ramped load test and confirm the throttle rate drops to near zero.

**Measured Before/After vs. Stated Target**

- TODO: P95 before fix: [your value]ms
- TODO: P95 after fix: [your value]ms
- TODO: CPU throttle rate before fix: [your value]
- TODO: CPU throttle rate after fix: [your value]
- Target: P95 < 500ms, throttle rate < 0.01

---

## Incident 2: Sequential Scan on Incidents Table

**Symptom**
`pg_stat_statements` shows high mean_exec_time on queries filtering by status. `EXPLAIN ANALYZE` shows a sequential scan on the 50,000-row incidents table for every filtered query.

**Root Cause**
No index exists on (status, created_at). Without this index, every query that filters by status or sorts by created_at must scan the entire table.

**Fix**

1. Confirm the sequential scan:
   ```bash
   docker compose -f week-2/docker-compose.yml exec db \
     psql -U appuser -d statustracker \
     -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM incidents WHERE status = 'open' ORDER BY created_at DESC LIMIT 10;"
   ```
   Look for `Seq Scan on incidents` in the output.

2. Create the index:
   ```bash
   docker compose -f week-2/docker-compose.yml exec db \
     psql -U appuser -d statustracker \
     -c "CREATE INDEX CONCURRENTLY idx_incidents_status_created ON incidents(status, created_at DESC);"
   ```
   The `CONCURRENTLY` keyword allows other queries to run while the index is being built.

3. Verify the index was created:
   ```bash
   docker compose -f week-2/docker-compose.yml exec db \
     psql -U appuser -d statustracker \
     -c "\di idx_incidents_status_created"
   ```
   You should see one row listing the index.

4. Re-run the EXPLAIN ANALYZE to confirm the query plan changed:
   ```bash
   docker compose -f week-2/docker-compose.yml exec db \
     psql -U appuser -d statustracker \
     -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM incidents WHERE status = 'open' ORDER BY created_at DESC LIMIT 10;"
   ```
   The output should now show `Index Scan` instead of `Seq Scan`.

**Measured Before/After vs. Stated Target**

- TODO: Mean query time before index: [your value]ms
- TODO: Mean query time after index: [your value]ms
- TODO: P95 latency before index: [your value]ms
- TODO: P95 latency after index: [your value]ms
- Target: P95 < 500ms

---

## Storage Check Before and After

**Before database seed:**
```
TODO: Output from `df -h` and `docker system df`
```

**After database seed:**
```
TODO: Output from `df -h` and `docker system df`
```

**Notes:**
- TODO: Any storage issues encountered or space constraints observed
