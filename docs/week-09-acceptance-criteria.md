# Sprint 5 Acceptance Criteria

**Sprint:** 5 (Weeks 9-10)
**Date Written:** TODO (must be written before Developers begin implementation)
**Quality Assurance Lead:** TODO

## Objective

Define what "done" means for Sprint 5 work before implementation begins. These criteria go beyond what the check script validates.

## Feature: Week 5 Metric Pre-Check

**Acceptance Criteria**

- [ ] Pre-check (Part 0) confirms Prometheus is scraping `container_cpu_cfs_throttled_seconds_total` metric
- [ ] If metric is missing, team follows the inline fix procedure in Part 0
- [ ] Team documents the pre-check result (pass/fail) in Google Doc

## Feature: Database Seeding

**Acceptance Criteria**

- [ ] Seeder script completes without errors
- [ ] Row count is approximately 50,000 (within 1% acceptable)
- [ ] Row count verified using `SELECT COUNT(*) FROM incidents;`
- [ ] Disk usage after seeding is documented in environment log

## Feature: Baseline Load Test

**Acceptance Criteria**

- [ ] `week-9/smoke-test.js` exists and is executable
- [ ] Test runs without syntax errors
- [ ] Test completes the 1-minute baseline run
- [ ] Metrics recorded: RPS, P50, P95, P99, error rate
- [ ] Results logged in team Google Doc under "Week 9 Baseline"
- [ ] Baseline P95 is measured before any fixes are applied

## Feature: Ramped Load Test and Diagnosis

**Acceptance Criteria**

- [ ] `week-9/ramped-test.js` exists and is executable
- [ ] Test runs the three-stage ramp (1m to 10 VU, 3m to 50 VU, 1m to 0 VU)
- [ ] Test runs while Grafana CPU panel is observable
- [ ] Prometheus query for CPU throttling metric returns a non-zero value before fixes
- [ ] `pg_stat_statements` identifies the slowest query
- [ ] EXPLAIN ANALYZE on the slowest query shows `Seq Scan` before index is created
- [ ] Team confirms database bottleneck exists before fix

## Feature: Infrastructure Fix (CPU Limit)

**Acceptance Criteria**

- [ ] CPU limit in Flask deployment identified (currently 100m)
- [ ] `manifests/flask-deployment.yaml` is updated to 500m
- [ ] Updated deployment is applied: `kubectl apply -f manifests/flask-deployment.yaml`
- [ ] Pod restarts and reaches Ready status
- [ ] CPU throttle rate after fix is near zero (< 0.01)
- [ ] Query: `rate(container_cpu_cfs_throttled_seconds_total{container="flask"}[5m])` returns ~0
- [ ] Ramped load test is re-run post-fix and metrics recorded

## Feature: Database Fix (Missing Index)

**Acceptance Criteria**

- [ ] Index `idx_incidents_status_created` is created on (status, created_at DESC)
- [ ] Index created with CONCURRENTLY option (does not block queries)
- [ ] Index existence verified: `\di idx_incidents_status_created` shows one row
- [ ] EXPLAIN ANALYZE on the same slow query now shows `Index Scan` instead of `Seq Scan`
- [ ] Query execution time improves measurably
- [ ] Index is not a temporary fix; it persists across restarts

## Feature: k6 Threshold Gate in CI

**Acceptance Criteria**

- [ ] `.github/workflows/ci.yml` includes a new `load-test-gate` job
- [ ] Job runs `k6 run week-9/smoke-test.js`
- [ ] Job fails the build if P95 exceeds 500ms or error rate exceeds 1%
- [ ] Threshold values in CI match the `smoke-test.js` thresholds
- [ ] Job runs after `build-and-push` (depends-on is correct)
- [ ] CI pipeline is tested: a commit triggers the new job

## Feature: Runbook Documentation

**Acceptance Criteria**

- [ ] `week-9/runbook.md` documents two incidents (CPU throttling, missing index)
- [ ] Each incident follows the format: Symptom, Root Cause, Fix, Measured Before/After vs. Stated Target
- [ ] Runbook includes actual measured values (not placeholders) from the team's tests
- [ ] Fix steps in the runbook are actionable and tested by the team
- [ ] Storage check output (df, docker system df) is included
- [ ] Runbook is committed to the repo

## Feature: Verification and Check Script

**Acceptance Criteria**

- [ ] `./scripts/check-week9.sh` exists and is executable
- [ ] Script verifies: seeded row count, index exists, CPU throttle rate near zero, k6 test passes thresholds
- [ ] Script runs clean (exit code 0) before deliverables are submitted
- [ ] Script output is clear and identifies which checks passed/failed

## Feature: Google Doc Updates

**Acceptance Criteria**

- [ ] Team Google Doc includes "Week 9 Baseline" section with baseline metrics
- [ ] Team Google Doc includes "Week 9 Storage Check" section with before/after disk usage
- [ ] Team Google Doc includes comparison table: metrics before fix vs. after fix vs. stated target
- [ ] Reflection questions answered (5 questions from lab directions)

## Cross-Role Verification

- [ ] System Admin confirms environment is healthy and prerequisites met before Dev work begins
- [ ] QA reviews all k6 scripts for correctness (no syntax errors, parameters match lab)
- [ ] QA verifies runbook steps are actually tested and work as written
- [ ] Developers commit meaningful messages explaining what was fixed and why
- [ ] Scrum Master ensures all tasks are tracked on the board and all team members understand their role

## Sign-Off

**QA Lead Signature (when criteria are met):** TODO
**Date:** TODO
