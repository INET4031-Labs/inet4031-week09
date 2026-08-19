# Week 9: End-to-End Performance Investigation

**Sprint 5 Kickoff | Synchronous**

## Overview
Load database with synthetic data, diagnose two performance problems, fix them, add k6 regression gate to CI.

## Key Activities
Database seeding (50k rows), USE method diagnosis, missing index identification, CPU throttling diagnosis, k6 threshold gates

## Learning Objectives
Use USE method, identify missing index, detect/fix CPU throttling, add regression prevention

## Deliverables
week-9/smoke-test.js and ramped-test.js, database index, CPU limit increase, week-9/runbook.md, k6 CI gate

## Key Sections
- **Part 1-4**: Detailed implementation steps with validation checks
- **Storage Check**: Disk usage and container metrics
- **Validation Checks**: Service/resource verification
- **Reflection Questions**: Deeper understanding and tradeoffs

**Status**: Capstone prep - Performance tuned and gates in place

---
*For complete step-by-step instructions, refer to the INET 4031 Lab Directions - Full Curriculum document in the course materials.*
