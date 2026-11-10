# Week 9: End-to-End Performance Investigation

**Sprint 5 Kickoff**

## Overview

In this lab, your team loads the incident tracker in your k3d cluster with tens of thousands of synthetic records, then investigates two performance problems: a database-layer bottleneck exposed at scale and an infrastructure-layer bottleneck caused by an intentionally low CPU limit. You'll use k6 for load testing, Prometheus queries from the command line for USE-method diagnosis, and PostgreSQL's own query-analysis tools for the database side. The lab closes with a permanent k6 threshold gate added to GitHub Actions.

**This lab's Part 0 pre-check verifies the Week 5 Prometheus dependency before anything else runs.** Use the exact metric name and query from the Wiki for that check, not a remembered or paraphrased version.

## Learning Objectives

- Use the USE method to identify which resource saturates first under load
- Diagnose a missing database index using PostgreSQL's query-analysis tools
- Diagnose CPU throttling using the metric verified in Week 5
- Add a k6 threshold gate to GitHub Actions as a permanent regression check

## Prerequisites

- Week 5 complete: Prometheus deployed with cAdvisor scraping verified (mandatory pre-check in Part 0), and `week-5/pq.sh` in your repo
- Week 8 complete: application running in your k3d cluster with data in the database
- `k6` installed on your team's VM (check with `k6 version`)
- Your team's Kubernetes port (8090 plus your team number) and Prometheus port (9090 plus your team number)

## Pulling This Week's Starter Content Into Your Team Repo

This repo (`inet4031-week09`) is instructor-provided starter/reference content for
Week 9, not something you clone standalone. Pull the pieces you need into your
team's single repo:

```bash
git clone https://github.com/INET4031-Labs/inet4031-week09.git temp-week09
rm -rf temp-week09/.git
mkdir -p week-9
cp -r temp-week09/docs/. docs/
cp temp-week09/scripts/check-week9.sh scripts/
rm -rf temp-week09
```

You create `week-9/smoke-test.js`, `week-9/ramped-test.js`, and `week-9/runbook.md`
yourself, following the wiki.

## Role Distribution

- **Scrum Master:** conducts the Sprint 4 review and closes the sprint, opens Sprint 5 issues, writes the retrospective summary
- **System Admin:** verifies environment prerequisites, documents disk usage before/after seeding, enables `pg_stat_statements` on the database
- **QA:** runs all validation checks, including that the CPU limit is restored both in the cluster and in `infrastructure/flask.tf`, verifies the k6 threshold gate passes in CI, signs off before submission
- **Developers:** implement k6 test scripts, fix the database index issue, update the CPU limit, add the k6 threshold gate to CI

## Deliverables

- `week-9/smoke-test.js` and `week-9/ramped-test.js` committed
- `week-9/runbook.md` committed using the two-incident format
- `manifests/db-deployment.yaml` updated with the `pg_stat_statements` startup flag
- `infrastructure/flask.tf` confirmed with the corrected CPU limit (500m), and the live Deployment restored to 500m with `kubectl`
- `.github/workflows/ci.yml` updated with a k6 threshold gate job
- Prediction for the **[PREDICT ONLY]** OpenTofu step in Google Doc
- Google Doc updated with baseline vs. post-fix comparison numbers
- `./scripts/check-week9.sh` runs clean

## Full Instructions

The complete step-by-step lab, including the exact metric name, PromQL queries, and diagnostic commands, is in this repo's Wiki tab. This README is a reference, not a substitute.
