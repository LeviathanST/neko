# Setup Neural Memory for Neko (Windows PowerShell)
#
# Usage:
#   .\scripts\setup-neural-memory.ps1              # basic install
#   .\scripts\setup-neural-memory.ps1 -WithGraph   # install + FalkorDB

param(
    [switch]$WithGraph,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\setup-neural-memory.ps1 [-WithGraph]"
    Write-Host "  -WithGraph  Also setup FalkorDB via Docker for graph-native storage"
    exit 0
}

function Info($msg)  { Write-Host "==> $msg" -ForegroundColor White }
function Ok($msg)    { Write-Host "  + $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "  x $msg" -ForegroundColor Red; exit 1 }

# ── Step 1: Check Python ─────────────────────────────────────────────

Info "Checking Python..."

$python = $null
foreach ($cmd in @("python3", "python", "py")) {
    try {
        $version = & $cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
        if ($version) {
            $parts = $version.Split(".")
            if ([int]$parts[0] -ge 3 -and [int]$parts[1] -ge 11) {
                $python = $cmd
                break
            }
        }
    } catch {}
}

if (-not $python) {
    Fail "Python 3.11+ required. Install from https://python.org"
}
Ok "Found $python ($version)"

# ── Step 2: Install neural-memory ─────────────────────────────────────

Info "Installing neural-memory..."

$nmemMcp = Get-Command nmem-mcp -ErrorAction SilentlyContinue
if ($nmemMcp) {
    Ok "neural-memory already installed (nmem-mcp found)"
} else {
    # Try pip first, fall back to pipx for externally-managed environments
    $pipResult = & $python -m pip install --user "neural-memory[all]" --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($pipResult -match "externally-managed-environment") {
            Warn "Python environment is externally managed, trying pipx..."
            $pipx = Get-Command pipx -ErrorAction SilentlyContinue
            if (-not $pipx) {
                Fail "pipx required for externally-managed Python. Install it first (e.g. scoop install pipx)"
            }
            pipx install "neural-memory[all]"
            if ($LASTEXITCODE -ne 0) {
                Fail "Failed to install neural-memory via pipx. Try: pipx install 'neural-memory[all]'"
            }
            Ok "neural-memory installed via pipx"
        } else {
            Fail "Failed to install neural-memory. Try: $python -m pip install neural-memory[all]"
        }
    } else {
        Ok "neural-memory installed"
    }
}

# ── Step 3: FalkorDB (optional) ──────────────────────────────────────

if ($WithGraph) {
    Info "Setting up FalkorDB..."

    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        Fail "Docker required for FalkorDB. Install from https://docker.com"
    }

    $running = docker ps --format '{{.Names}}' 2>$null | Select-String "falkordb"
    if ($running) {
        Ok "FalkorDB already running"
    } else {
        docker run -d `
            --name neko-falkordb `
            -p 6380:6379 `
            -v neko_falkordb_data:/data `
            --restart unless-stopped `
            --memory 512m `
            falkordb/falkordb:latest
        if ($LASTEXITCODE -ne 0) { Fail "Failed to start FalkorDB container" }
        Ok "FalkorDB started on port 6380"
    }

    Info "Waiting for FalkorDB to be ready..."
    for ($i = 1; $i -le 15; $i++) {
        $ping = docker exec neko-falkordb redis-cli -p 6379 ping 2>$null
        if ($ping -eq "PONG") {
            Ok "FalkorDB is healthy"
            break
        }
        if ($i -eq 15) { Fail "FalkorDB did not become healthy in 15 seconds" }
        Start-Sleep -Seconds 1
    }
}

# ── Step 4: Configure embedding ──────────────────────────────────────

$nmemConfig = Join-Path $HOME ".neuralmemory" "config.toml"
$nmemDir = Split-Path $nmemConfig

if (-not (Test-Path $nmemConfig)) {
    if (-not (Test-Path $nmemDir)) {
        New-Item -ItemType Directory -Path $nmemDir -Force | Out-Null
    }
    @"
[embedding]
enabled = true
provider = "auto"
"@ | Out-File -FilePath $nmemConfig -Encoding utf8
    Ok "Created $nmemConfig with auto embedding"
} else {
    Ok "Neural memory config already exists at $nmemConfig"
}

# ── Step 5: FalkorDB config ──────────────────────────────────────────

if ($WithGraph) {
    $content = Get-Content $nmemConfig -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch "falkordb") {
        @"

[storage]
backend = "falkordb"

[falkordb]
host = "localhost"
port = 6380
"@ | Add-Content -Path $nmemConfig
        Ok "Configured FalkorDB backend in $nmemConfig"
    } else {
        Ok "FalkorDB already configured in $nmemConfig"
    }
}

# ── Step 6: Verify ────────────────────────────────────────────────────

Info "Verifying installation..."

$nmemMcp = Get-Command nmem-mcp -ErrorAction SilentlyContinue
if ($nmemMcp) {
    Ok "nmem-mcp is available"
} else {
    Warn "nmem-mcp not in PATH - you may need to restart your shell"
}

$nmem = Get-Command nmem -ErrorAction SilentlyContinue
if ($nmem) {
    nmem health 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "nmem health check passed" }
    else { Warn "nmem health check had issues (may need first-use initialization)" }
}

Write-Host ""
Write-Host "Neural Memory setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  NeuralMemory config: $nmemConfig"
if ($WithGraph) {
    Write-Host "  FalkorDB: localhost:6380 (container: neko-falkordb)"
}
Write-Host ""
Write-Host "  Next: configure your runtime's MCP settings to use 'nmem-mcp'."
Write-Host "  See SETUP.md for per-runtime instructions."
