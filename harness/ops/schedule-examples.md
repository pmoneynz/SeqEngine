# Scheduling Examples

## Daily cleanup
```bash
0 4 * * * cd /path/to/repo && bash harness/ops/run-daily-gc.sh .
```

## Weekly metrics and report
```bash
0 5 * * 1 cd /path/to/repo && bash harness/quality/collect-metrics.sh . && bash harness/quality/weekly-report.sh .
```
