<#
.SYNOPSIS
  Start an interactive 32-bit (i386) Debian dev shell in Docker.

.DESCRIPTION
  - Builds image 'debian-i386-dev' if missing (uses buildx --load when possible).
  - Runs container with /work bound to your current directory (or a specified folder).
  - Opens an interactive bash shell inside the container.

.PARAMETER WorkDir
  Host directory to mount into the container at /work. Defaults to current directory.

.PARAMETER ImageName
  Docker image name to use/build. Default: debian-i386-dev

.PARAMETER Rebuild
  Force rebuild of the image before running.

.PARAMETER NoBuildx
  Skip buildx and use classic 'docker build' even if buildx is available.

.EXAMPLE
  .\Start-Dev32.ps1

.EXAMPLE
  .\Start-Dev32.ps1 -WorkDir "D:\Projects\my32bit" -Rebuild

#>

[CmdletBinding()]
param(
  [string]$WorkDir = (Get-Location).Path,
  [string]$ImageName = "debian-i386-dev",
  [switch]$Rebuild,
  [switch]$NoBuildx
)

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# --- pre-launch checks ---
# Check Docker CLI and if Docker is running
try {
  $null = docker version --format '{{.Server.Version}}' 2>$null
} catch {
  Write-Err "Docker does not appear to be installed or running. Please start Docker Desktop and try again."
  exit 1
}

# Normalize and Resolve WorkDir
$WorkDir = (Resolve-Path -LiteralPath $WorkDir).Path
if (-not (Test-Path -LiteralPath $WorkDir)) {
  Write-Err "WorkDir does not exist: $WorkDir"
  exit 1
}

# Ensure path is a DIRECTORY
if (-not (Get-Item -LiteralPath $WorkDir).PSIsContainer) {
  Write-Err "WorkDir is not a directory: $WorkDir"
  exit 1
}

Write-Info "Using WorkDir: $WorkDir"
Write-Info "Image name:    $ImageName"

# --- Detect if image exists built on system ---
$needBuild = $true
if (-not $Rebuild) {
  $inspect = docker image inspect $ImageName 2>$null
  if ($LASTEXITCODE -eq 0) {
    $needBuild = $false
    Write-Info "Image '$ImageName' already exists. Skipping build."
  } else {
    Write-Info "Image '$ImageName' not found; will build."
  }
} else {
  Write-Info "Rebuild requested."
}

# --- Build (if needed) ---
if ($needBuild) {
  # Look for Dockerfile in current directory
  $dockerfilePath = Join-Path -Path (Get-Location).Path -ChildPath "Dockerfile"
  if (-not (Test-Path -LiteralPath $dockerfilePath)) {
    Write-Err "No Dockerfile found in: $(Get-Location). Provide a Dockerfile or run the script from the folder that contains it."
    exit 1
  }

  # Check whether buildx is available
  $hasBuildx = $false
  if (-not $NoBuildx) {
    try {
      $bx = docker buildx version 2>$null
      if ($LASTEXITCODE -eq 0) { $hasBuildx = $true }
    } catch { $hasBuildx = $false }
  }

  if ($hasBuildx) {
    Write-Info "Building with buildx (linux/386) and loading into local Docker..."
    docker buildx build --platform linux/386 -t $ImageName --load .
    if ($LASTEXITCODE -ne 0) {
      Write-Err "buildx build failed."
      exit 1
    }
  } else {
    Write-Warn "buildx not available or disabled; falling back to classic 'docker build'."
    Write-Info "Building image (Dockerfile should contain 'FROM --platform=linux/386 ...')..."
    docker build -t $ImageName .
    if ($LASTEXITCODE -ne 0) {
      Write-Err "docker build failed."
      exit 1
    }
  }
}

# --- Run /bin/bash  ---
# Use --mount for robust win path handling
Write-Info "Starting container shell..."
$runArgs = @(
  "run", "--platform", "linux/386",
  "-it", "--rm",
  "--mount", "type=bind,source=$WorkDir,target=/work",
  "-w", "/work",
  $ImageName
)

# --- Launch ---
docker @runArgs
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  Write-Err "Container exited with code $exitCode"
  exit $exitCode
}
