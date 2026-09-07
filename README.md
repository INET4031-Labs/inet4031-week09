# Week 9: End-to-End Performance Investigation

**Sprint 5 Kickoff**

## Overview

In this lab, your team loads the incident tracker with tens of thousands of synthetic records, then investigates two performance problems: a database-layer bottleneck exposed at scale and an infrastructure-layer bottleneck caused by an intentionally low CPU limit. You'll use k6 for load testing, Prometheus/Grafana for USE-method diagnosis, and PostgreSQL's own query-analysis tools for the database side. The lab closes with a permanent k6 threshold gate added to GitHub Actions.

**This lab's Part 0 pre-check verifies the Week 5 Prometheus dependency before anything else runs.** Use the exact metric name and query from the Wiki for that check, not a remembered or paraphrased version.

## Learning Objectives

- Use the USE method to identify which resource saturates first under load
- Diagnose a missing database index using PostgreSQL's query-analysis tools
- Diagnose CPU throttling using the metric verified in Week 5
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

## Role Distribution

- **Scrum Master:** conducts the Sprint 4 review and closes the sprint, opens Sprint 5 issues, writes the retrospective summary
- **System Admin:** verifies environment prerequisites, documents disk usage before/after seeding
- **QA:** runs all validation checks including the `tofu plan` drift check, verifies the k6 threshold gate passes in CI, signs off before submission
- **Developers:** implement k6 test scripts, fix the database index issue, update the CPU limit, add the k6 threshold gate to CI

## Deliverables

- `week-9/smoke-test.js` and `week-9/ramped-test.js` committed
- `week-9/runbook.md` committed using the two-incident format
- `infrastructure/flask.tf` confirmed/updated with the corrected CPU limit (applied via `tofu apply`)
- `.github/workflows/ci.yml` updated with a k6 threshold gate job
- `tofu plan` shows no drift
- Google Doc updated with baseline vs. post-fix comparison numbers
- `./scripts/check-week9.sh` runs clean

## Full Instructions

The complete step-by-step lab, including the exact metric name, PromQL query, and diagnostic commands, is in this repo's Wiki tab. This README is a reference, not a substitute.
