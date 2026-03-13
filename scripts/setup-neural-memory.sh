#!/usr/bin/env bash
# Setup Neural Memory for Neko
# Cross-platform: Linux, macOS, Windows (Git Bash/WSL)
#
# Usage:
#   ./scripts/setup-neural-memory.sh              # basic install
#   ./scripts/setup-neural-memory.sh --with-graph  # install + FalkorDB

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BOLD}==> ${NC}$1"; }
ok()    { echo -e "${GREEN}  ✓${NC} $1"; }
warn()  { echo -e "${YELLOW}  !${NC} $1"; }
fail()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }

WITH_GRAPH=false
for arg in "$@"; do
    case "$arg" in
        --with-graph) WITH_GRAPH=true ;;
        --help|-h)
            echo "Usage: $0 [--with-graph]"
            echo "  --with-graph  Also setup FalkorDB via Docker for graph-native storage"
            exit 0
            ;;
    esac
done

# ── Step 1: Check Python ─────────────────────────────────────────────

info "Checking Python..."

PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        version=$("$cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
            PYTHON="$cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    fail "Python 3.11+ required. Install from https://python.org or your package manager."
fi
ok "Found $PYTHON ($version)"

# ── Step 2: Install neural-memory ─────────────────────────────────────

info "Installing neural-memory..."

if command -v nmem-mcp &>/dev/null; then
    ok "neural-memory already installed (nmem-mcp found)"
else
    # Detect externally-managed Python environments (Arch, Fedora 38+, Debian 12+, etc.)
    # Check for the PEP 668 marker file that pip uses
    EXTERNALLY_MANAGED=false
    STDLIB_PATH=$("$PYTHON" -c "import sysconfig; print(sysconfig.get_path('stdlib'))" 2>/dev/null)
    if [ -f "$STDLIB_PATH/EXTERNALLY-MANAGED" ]; then
        EXTERNALLY_MANAGED=true
    fi

    if [ "$EXTERNALLY_MANAGED" = true ]; then
        # Use pipx for externally-managed environments
        if ! command -v pipx &>/dev/null; then
            warn "Python environment is externally managed (e.g. Arch Linux)"
            fail "pipx required. Install it first: sudo pacman -S python-pipx (Arch) or sudo apt install pipx (Debian/Ubuntu)"
        fi
        pipx install "neural-memory[all]" || \
            fail "Failed to install neural-memory via pipx. Try: pipx install 'neural-memory[all]'"
        ok "neural-memory installed via pipx"
    else
        "$PYTHON" -m pip install --user "neural-memory[all]" --quiet || \
            fail "Failed to install neural-memory. Try: $PYTHON -m pip install neural-memory[all]"
        ok "neural-memory installed"
    fi
fi

# Verify nmem-mcp is in PATH
if ! command -v nmem-mcp &>/dev/null; then
    # Check common bin locations (pip --user, pipx, macOS, Windows)
    for dir in "$HOME/.local/bin" "$HOME/Library/Python/3.*/bin" "$APPDATA/Python/Python3*/Scripts"; do
        # shellcheck disable=SC2086
        for expanded in $dir; do
            if [ -f "$expanded/nmem-mcp" ]; then
                warn "nmem-mcp found at $expanded but not in PATH"
                warn "Add to your shell profile: export PATH=\"$expanded:\$PATH\""
                break 2
            fi
        done
    done
fi

# ── Step 3: FalkorDB (optional) ──────────────────────────────────────

if [ "$WITH_GRAPH" = true ]; then
    info "Setting up FalkorDB..."

    if ! command -v docker &>/dev/null; then
        fail "Docker required for FalkorDB. Install from https://docker.com"
    fi

    # Check if FalkorDB is already running
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q falkordb; then
        ok "FalkorDB already running"
    else
        # Pull and start FalkorDB
        docker run -d \
            --name neko-falkordb \
            -p 6380:6379 \
            -v neko_falkordb_data:/data \
            --restart unless-stopped \
            --memory 512m \
            falkordb/falkordb:latest \
            || fail "Failed to start FalkorDB container"
        ok "FalkorDB started on port 6380"
    fi

    # Wait for healthy
    info "Waiting for FalkorDB to be ready..."
    for i in $(seq 1 15); do
        if docker exec neko-falkordb redis-cli -p 6379 ping &>/dev/null; then
            ok "FalkorDB is healthy"
            break
        fi
        if [ "$i" -eq 15 ]; then
            fail "FalkorDB did not become healthy in 15 seconds"
        fi
        sleep 1
    done
fi

# ── Step 4: Configure embedding ──────────────────────────────────────

NMEM_CONFIG="$HOME/.neuralmemory/config.toml"
if [ ! -f "$NMEM_CONFIG" ]; then
    mkdir -p "$HOME/.neuralmemory"
    cat > "$NMEM_CONFIG" << 'TOML'
[embedding]
enabled = true
provider = "auto"
TOML
    ok "Created $NMEM_CONFIG with auto embedding"
else
    ok "Neural memory config already exists at $NMEM_CONFIG"
fi

# ── Step 5: FalkorDB config (if --with-graph) ────────────────────────

if [ "$WITH_GRAPH" = true ]; then
    if ! grep -q "falkordb" "$NMEM_CONFIG" 2>/dev/null; then
        cat >> "$NMEM_CONFIG" << 'TOML'

[storage]
backend = "falkordb"

[falkordb]
host = "localhost"
port = 6380
TOML
        ok "Configured FalkorDB backend in $NMEM_CONFIG"
    else
        ok "FalkorDB already configured in $NMEM_CONFIG"
    fi
fi

# ── Step 6: Verify ────────────────────────────────────────────────────

info "Verifying installation..."

if command -v nmem-mcp &>/dev/null; then
    ok "nmem-mcp is available"
else
    warn "nmem-mcp not in PATH — you may need to restart your shell"
fi

if command -v nmem &>/dev/null; then
    nmem health 2>/dev/null && ok "nmem health check passed" || warn "nmem health check had issues (may need first-use initialization)"
fi

echo ""
echo -e "${GREEN}${BOLD}Neural Memory setup complete!${NC}"
echo ""
echo "  NeuralMemory config: $NMEM_CONFIG"
if [ "$WITH_GRAPH" = true ]; then
    echo "  FalkorDB: localhost:6380 (container: neko-falkordb)"
fi
echo ""
echo "  Next: configure your runtime's MCP settings to use 'nmem-mcp'."
echo "  See SETUP.md for per-runtime instructions."
