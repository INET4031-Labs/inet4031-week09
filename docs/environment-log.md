# Environment Log

## Sprint 5 Entry (Week 9)

**Date:** TODO
**System Admin:** TODO
**Status:** TODO (In Progress / Complete)

### Pre-Lab Environment Snapshot

**Disk Usage Before Database Seed**
```
TODO: Output from `df -h`
```

**Docker System Status Before Database Seed**
```
TODO: Output from `docker system df`
```

**Cluster Status**
```
TODO: Output from `k3d cluster list`
TODO: Output from `kubectl get pods`
TODO: Output from `kubectl get pods -n monitoring`
```

**k6 Installation Verification**
```
TODO: Output from `k6 version`
```

### Infrastructure Decisions Made

1. TODO: Database seeding approach (batch size, connection pool settings, etc.)
2. TODO: CPU limit chosen for Flask deployment after fix (rationale)
3. TODO: Load test parameters (VU count, ramp duration, etc.)

### Issues Encountered and Resolutions

**Issue:** TODO (if any)
**Resolution:** TODO

**Issue:** TODO (if any)
**Resolution:** TODO

### Mid-Sprint Environment Checkpoint (if applicable)

**Date:** TODO

```
TODO: Output from `kubectl top pods`
TODO: Output from `df -h`
TODO: Output from `docker system df`
```

### Post-Lab Environment Snapshot

**Disk Usage After Database Seed and Fixes**
```
TODO: Output from `df -h`
```

**Docker System Status After Database Seed and Fixes**
```
TODO: Output from `docker system df`
```

**Cluster Status After Fixes**
```
TODO: Output from `k3d cluster list`
TODO: Output from `kubectl get pods`
TODO: Output from `kubectl get pods -n monitoring`
```

### Environment Health Summary

- Disk available: TODO GB
- Database rows: TODO (~50,000 expected)
- Index created: TODO (yes/no)
- CPU limit updated: TODO (yes/no)
- k6 tests passing threshold: TODO (yes/no)
- Any environment rework needed before Sprint 6: TODO (yes/no, describe if yes)

### Notes for Next Sprint

TODO: Any environment prerequisites for Week 10/Sprint 5 continuation that the next System Admin should know about.
