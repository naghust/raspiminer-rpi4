#!/usr/bin/env bash
# RasPiMiner — installer for Raspberry Pi 4 (aarch64 / Bookworm 64-bit)
# Fork of jvxis/nerdminer-pizero, adapted for Pi 4 — no LCD required.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo ">> Repo: $REPO_DIR"

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "!! WARNING: This script is optimised for aarch64 (Pi 4 64-bit)."
    echo "!! Detected: $ARCH. Continuing, but compiler flags may not be optimal."
fi

echo ">> Installing system packages (no LCD/SPI packages needed)..."
sudo apt-get update
sudo apt-get install -y \
    build-essential automake autoconf pkg-config git \
    libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev \
    python3-pil python3-numpy python3-requests

echo ">> Building pooler/cpuminer for aarch64 (Pi 4)..."
BUILD_DIR="${REPO_DIR}/.build/cpuminer"
CPUMINER_COMMIT=5f02105940edb61144c09a7eb960bba04a10d5b7
SUGGEST_PATCH="${REPO_DIR}/patches/0001-cpuminer-suggest-difficulty.patch"

if [ ! -d "$BUILD_DIR/.git" ]; then
    git clone https://github.com/pooler/cpuminer.git "$BUILD_DIR"
fi
cd "$BUILD_DIR"
git checkout -q -- . 2>/dev/null || true
git fetch -q origin 2>/dev/null || true
git checkout -q "$CPUMINER_COMMIT"
git apply "$SUGGEST_PATCH"
echo ">> Applied suggest_difficulty patch."
./autogen.sh
./configure CFLAGS="-O3 -march=native -mtune=native"
make -j2
sudo make install
cd "$REPO_DIR"

echo ">> Verifying installation..."
minerd --version

echo ">> Preparing log directory..."
sudo mkdir -p /var/log/pizero-miner
sudo chown "$USER" /var/log/pizero-miner

if [ ! -f "${REPO_DIR}/config.ini" ]; then
    cp "${REPO_DIR}/config.example.ini" "${REPO_DIR}/config.ini"
    echo ">> Created config.ini from example. Edit it before running!"
fi

cat <<EOF

========================================
  RasPiMiner — Installation complete!
========================================

Next steps:
  1. Edit config.ini:
        nano config.ini
     Set your [wallet] address, [pool] url, and [miner] threads (2 recommended).

  2. Quick test (two terminals):
        Terminal 1:  bash scripts/run-cpuminer.sh
        Terminal 2:  bash monitor.sh

  3. Run as a service (auto-start on boot):
        sudo cp systemd/*.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable --now pizero-cpuminer

EOF
