#!/usr/bin/env python3
import sys, re, csv

if len(sys.argv) != 2:
    print("Usage: parse_stats.py <stats.txt>", file=sys.stderr)
    sys.exit(1)

stats_file = sys.argv[1]
rows = []
# Collect these keys if present (adapt as needed):
keep = [
    "sim_seconds",
    "system.cpu.power_model.power",
    "system.cpu.power_model.dynamic",
    "system.cpu.power_model.static",
    "system.mem_ctrl.power_model.power",
    "system.mem_ctrl.power_model.dynamic",
    "system.mem_ctrl.power_model.static",
    "system.cpu.ipc",
]

with open(stats_file, "r", encoding="utf-8") as f:
    for line in f:
        if line.startswith("---------- End") or line.strip().startswith("---------- Begin"):
            continue
        m = re.match(r"^(\S+)\s+([\d.eE+-]+)\s+#?\s*(.*)$", line.strip())
        if not m:
            continue
        key, val, _ = m.groups()
        if key in keep:
            rows.append((key, float(val)))

# Write a tiny CSV (key, value). For time series, you can adapt fs scripts or run with checkpoints.
writer = csv.writer(sys.stdout)
writer.writerow(["metric", "value"])
for k, v in rows:
    writer.writerow([k, v])