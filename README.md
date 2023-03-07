
```
psql -v test=diff_mismatch.sql -f runner/test_runner.sql
```

```
xPSQL_WAIT_PORTX=1 PAGER=less psql -h localhost -U dev tsdb7 -v test=diff_mismatch.sql -f runner/test_runner.sql
```
