# Sprint 5 QA Report

**Sprint:** 5 (Weeks 9-10)
**Date:** TODO (end of sprint)
**Quality Assurance Lead:** TODO

## Check Script Results

**Script:** `./scripts/check-week9.sh`
**Date Run:** TODO
**Exit Code:** TODO (0 = pass, non-zero = fail)

```
TODO: Paste full output from check script
```

### Check-by-Check Results

| Check | Status | Notes |
|---|---|---|
| Seeded row count ~50k | TODO | TODO |
| CPU throttle rate < 0.01 after fix | TODO | TODO |
| Index `idx_incidents_status_created` exists | TODO | TODO |
| k6 smoke test passes P95<500ms threshold | TODO | TODO |

## Acceptance Criteria Review

**Total Criteria:** 30+
**Passed:** TODO
**Failed:** TODO
**Rework Required:** TODO (yes/no)

### Failed Criteria (if any)

| Criterion | Why It Failed | Rework Needed |
|---|---|---|
| TODO | TODO | TODO |

## Verification Steps Performed By QA

1. **Pre-check metric verification**
   - [ ] Manually confirmed Prometheus is scraping `container_cpu_cfs_throttled_seconds_total`
   - [ ] Status: TODO (pass/fail)

2. **k6 test syntax validation**
   - [ ] `smoke-test.js` has no syntax errors
   - [ ] `ramped-test.js` has no syntax errors
   - [ ] Thresholds are correctly defined
   - [ ] Status: TODO (pass/fail)

3. **Database fixes validation**
   - [ ] Index creation command documented correctly
   - [ ] Index exists and is named correctly
   - [ ] EXPLAIN ANALYZE shows Index Scan after fix
   - [ ] Status: TODO (pass/fail)

4. **Infrastructure fixes validation**
   - [ ] Flask deployment CPU limit changed from 100m to 500m
   - [ ] Deployment was successfully applied
   - [ ] Pod restarted and reached Ready status
   - [ ] Status: TODO (pass/fail)

5. **CI integration validation**
   - [ ] `.github/workflows/ci.yml` has new `load-test-gate` job
   - [ ] Job depends on `build-and-push`
   - [ ] Job runs k6 with correct thresholds
   - [ ] Tested: a commit triggers the new job
   - [ ] Status: TODO (pass/fail)

6. **Runbook completeness**
   - [ ] Two incidents documented with all required sections
   - [ ] Fix steps are tested and work
   - [ ] Measured values are filled in (not placeholders)
   - [ ] Status: TODO (pass/fail)

7. **Google Doc updates**
   - [ ] Baseline metrics recorded
   - [ ] Post-fix metrics recorded
   - [ ] Comparison table present
   - [ ] Reflection questions answered
   - [ ] Status: TODO (pass/fail)

## Issues Found During QA (and rework if applicable)

**Issue 1:** TODO (if any)
- **Severity:** High / Medium / Low
- **Root Cause:** TODO
- **Rework Required:** TODO
- **Status:** TODO (fixed/still open)

**Issue 2:** TODO (if any)
- **Severity:** High / Medium / Low
- **Root Cause:** TODO
- **Rework Required:** TODO
- **Status:** TODO (fixed/still open)

## Deliverable Commit Audit

| Deliverable | File/Path | Status | Notes |
|---|---|---|---|
| Smoke test | `week-9/smoke-test.js` | TODO (present/missing) | TODO |
| Ramped test | `week-9/ramped-test.js` | TODO (present/missing) | TODO |
| Runbook | `week-9/runbook.md` | TODO (present/missing) | TODO |
| Flask deployment updated | `infrastructure/flask.tf` | TODO (updated/not updated) | TODO |
| CI gate added | `.github/workflows/ci.yml` | TODO (added/not added) | TODO |
| Check script | `scripts/check-week9.sh` | TODO (present/missing) | TODO |

## Performance Metrics Summary

| Metric | Before Fix | After Fix | Target | Status |
|---|---|---|---|---|
| P95 response time | TODO | TODO | < 500ms | TODO |
| CPU throttle rate | TODO | TODO | < 0.01 | TODO |
| Database query time (mean) | TODO | TODO | < target | TODO |
| Error rate | TODO | TODO | < 1% | TODO |

## Cross-Week Dependencies

- [ ] Week 5 Prometheus metric (`container_cpu_cfs_throttled_seconds_total`) available (verified in Part 0)
- [ ] Week 8 database application running with data
- [ ] k6 tool installed from Week 5 and functioning

## Recommendations for Next Sprint

TODO: Any process or technical improvements for Sprint 6?

## QA Sign-Off

**Status:** TODO (Ready for Release / Needs Rework)

If rework is needed, list the critical issues that must be fixed:
- TODO
- TODO

**QA Lead Signature:** TODO
**Date:** TODO
