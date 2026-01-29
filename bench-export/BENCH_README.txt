ThemeToggle Benchmark Export

Run in PowerShell:
  .\\tools\\bench.ps1 -Iterations 1000

Suggested throttled run:
  .\\tools\\bench.ps1 -Iterations 1000 -SettleMs 750 -BatchSize 50 -BatchPauseMs 4000 -JitterMs 150

Output:
  bench.csv in the same folder.
