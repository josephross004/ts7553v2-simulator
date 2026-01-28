#!/usr/bin/env bash
set -euo pipefail

GEM5_BIN=${GEM5_BIN:-/opt/gem5/build/ARM/gem5.opt}
CFG=${CFG:-/work/configs/ts7553v2_power.py}
ASSETS=${ASSETS:-/assets}
RUNS=${RUNS:-/runs}
OUTDIR="${RUNS}/run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

KERNEL=${KERNEL:-$ASSETS/vmlinux-armv7}
DISK=${DISK:-$(ls -1 $ASSETS/*.img | head -n1)}

echo "[INFO] Kernel: $KERNEL"
echo "[INFO] Disk:   $DISK"
echo "[INFO] Output: $OUTDIR"

"$GEM5_BIN" \
  --outdir="$OUTDIR" \
  "$CFG" \
  --kernel="$KERNEL" \
  --disk="$DISK" \
  --num-cpus="${NUM_CPUS:-1}" \
  --cpu-clock="${CPU_CLOCK:-1GHz}" \
  --sys-clock="${SYS_CLOCK:-1GHz}" \
  --mem-size="${MEM_SIZE:-512MB}"

# Convert power-related stats to CSV
python3 /work/scripts/parse_stats.py "$OUTDIR/stats.txt" > "$OUTDIR/power.csv"
echo "[OK] Stats: $OUTDIR/stats.txt"
echo "[OK] Power CSV: $OUTDIR/power.csv"