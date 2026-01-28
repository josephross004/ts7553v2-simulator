[CmdletBinding()]
param(
  [string]$ImageName = "gem5-armfs",
  [string]$ProjectDir = (Get-Location).Path
)

function Info($m){ Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Normalize/verify project dir
try {
  $ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path
} catch {
  Err "Project directory not found: $ProjectDir"
  exit 1
}

# Ensure folders exist on host (so --mount has valid paths)
$assets = Join-Path $ProjectDir "assets"
$runs   = Join-Path $ProjectDir "runs"
if (!(Test-Path $assets)) { New-Item -Type Directory -Path $assets | Out-Null }
if (!(Test-Path $runs))   { New-Item -Type Directory -Path $runs   | Out-Null }

# 1) Build the image
Info "Building image '$ImageName' from: $ProjectDir"
docker build -t $ImageName "$ProjectDir"
if ($LASTEXITCODE -ne 0) {
  Err "Build failed."
  exit $LASTEXITCODE
}

# 2) Fetch ARM full-system assets (kernel/bootloader + disk image)
Info "Fetching ARM full-system assets into: $assets"
docker run --rm `
  --mount "type=bind,source=$ProjectDir,target=/work" `
  --mount "type=bind,source=$assets,target=/assets" `
  --mount "type=bind,source=$runs,target=/runs" `
  -w /work `
  $ImageName bash -lc "./scripts/get_arm_fs_assets.sh"
if ($LASTEXITCODE -ne 0) {
  Err "Failed to download FS assets."
  exit $LASTEXITCODE
}

# 3) Run gem5 (power-enabled FS sim)
Info "Running gem5 FS + power; results will go under: $runs"
docker run --rm -it `
  --mount "type=bind,source=$ProjectDir,target=/work" `
  --mount "type=bind,source=$assets,target=/assets" `
  --mount "type=bind,source=$runs,target=/runs" `
  -w /work `
  $ImageName bash -lc "./scripts/run_fs_power.sh"
if ($LASTEXITCODE -ne 0) {
  Err "gem5 run failed."
  exit $LASTEXITCODE
}

Info "Done. Check the latest subfolder in 'runs\\' for stats.txt and power.csv."