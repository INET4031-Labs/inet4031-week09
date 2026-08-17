# Week 9: End-to-End Performance Investigation

**Sprint 5 Kickoff | Synchronous**

## Overview

In this lab, your team loads the incident tracker with tens of thousands of synthetic records, then investigates two performance problems: a database-layer bottleneck exposed by query patterns at scale and an infrastructure-layer bottleneck caused by an intentionally low CPU limit. You will use k6 for load testing, Prometheus and Grafana for USE method diagnosis, `pg_stat_statements` and `EXPLAIN (ANALYZE, BUFFERS)` for database-layer diagnosis, and `rate(container_cpu_cfs_throttled_seconds_total[5m])` for infrastructure-layer diagnosis. The lab closes with a k6 threshold gate added to GitHub Actions.

## Learning Objectives

- Use the USE method to identify which resource saturates first under load
- Diagnose a missing database index using `pg_stat_statements` and `EXPLAIN (ANALYZE, BUFFERS)`
- Diagnose CPU throttling using `rate(container_cpu_cfs_throttled_seconds_total[5m])`
- Add a k6 threshold gate to GitHub Actions as a permanent regression check

## Prerequisites

- Week 5 complete: Prometheus deployed with kubelet scraping verified (mandatory pre-check in Part 0)
- Week 8 complete: application has data in the database
- k6 installed from Week 5

## Pulling This Week's Starter Content Into Your Team Repo

This repo (`inet4031-week09`) is instructor-provided starter/reference content for
Week 9, not something you clone standalone. Pull the pieces you need into your
team's single repo:

```bash
git remote add week9 https://github.com/INET4031-Labs/inet4031-week09.git
git fetch week9
git checkout week9/main -- ramped-test.js runbook.md smoke-test.js scripts docs
mkdir -p week-9
mv ramped-test.js runbook.md smoke-test.js week-9/
git remote remove week9
```

Do this before you start editing `week-9/` locally, or your local changes will be
silently overwritten by the checkout.

## Architecture Notice

This lab assumes the university container platform permits `--privileged` mode. This has not been confirmed by the professor. If unavailable, the container-per-team model fails and the course must fall back to individual student VMs.

## Lab Structure

- **Part 0:** Pre-check - Verify Week 5 Prometheus metric is available
- **Sprint Review:** Review and close Sprint 4
- **Part 1:** Load the database with ~50,000 synthetic records
- **Part 2:** Baseline load test and metric collection
- **Part 3:** Ramped load test and USE method diagnosis
- **Part 4:** Fix both issues and measure improvement
- **Part 5:** Add k6 threshold gate to GitHub Actions CI pipeline
- **Runbook:** Document performance issues and fixes

## Deliverables

- `week-9/smoke-test.js` - Baseline load test script
- `week-9/ramped-test.js` - Ramped load test script
- `week-9/runbook.md` - Performance troubleshooting runbook
- `manifests/flask-deployment.yaml` - Updated with corrected CPU limit
- `.github/workflows/ci.yml` - Updated with k6 threshold gate
- `./scripts/check-week9.sh` - Validation check script
- Google Doc - Updated with baseline vs post-fix comparison numbers
- Role-artifact documents - Retrospective, environment log, acceptance criteria, QA report

## Key Concepts

**USE Method:** Utilization, Saturation, Errors. Helps identify which resource (CPU, memory, disk, network) becomes the bottleneck under load.

**k6 Thresholds:** Automated performance gates in CI that fail the build if response time or error rate exceed defined limits.

**CPU Throttling:** When a container requests more CPU than its limit allows, the kernel throttles it. Observable via `container_cpu_cfs_throttled_seconds_total`.

**Database Query Analysis:** `pg_stat_statements` shows query execution times. `EXPLAIN ANALYZE` shows the query plan and actual row counts. Sequential scans on large tables indicate missing indexes.

## Files in This Directory

```
week-09/
├── README.md                          (this file)
├── smoke-test.js                      (baseline k6 test)
├── ramped-test.js                     (ramped-load k6 test)
├── runbook.md                         (performance troubleshooting guide)
└── docs/
    ├── sprint-5-retrospective.md      (SM artifact - blank template)
    ├── week-09-environment-log.md             (SA artifact - blank template)
    ├── week-09-acceptance-criteria.md         (QA artifact - blank template)
    └── qa-report-5.md                 (QA artifact - blank template)
```

## Quick Start

1. Run Part 0 pre-check to verify Prometheus is scraping cAdvisor metrics
2. Follow Parts 1-5 in sequence
3. Record all measurements in the team Google Doc
4. Commit test scripts and runbook to the repo
5. Update manifests and CI config
6. Run `./scripts/check-week9.sh` to validate

## Role-Specific Responsibilities

**Scrum Master**
- Conduct Sprint 4 review and close the sprint
- Open Sprint 5 issues on the board
- Write sprint 5 retrospective summary

**System Admin**
- Verify environment prerequisites (k3d cluster, Prometheus, k6 installed)
- Document disk usage before and after seeding database
- Monitor and report any environment issues during tests

**Quality Assurance**
- Write acceptance criteria before Developers implement
- Run all validation checks
- Sign off before deliverables are submitted
- Write QA report with check script results

**Developers**
- Implement k6 test scripts
- Fix database index issue
- Update CPU limit in Flask deployment
- Add k6 threshold gate to GitHub Actions CI
- Update team Google Doc with measurements
