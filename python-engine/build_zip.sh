#!/bin/bash

# Configuration
PYTHON_VER="3.12.6"
RELEASE_TAG="20240909"
WORK_DIR="build_temp"
DIST_ZIP="../spade/assets/python_dist.zip"

# Color codes for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}[INFO] Detecting system environment...${NC}"
RAW_OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$RAW_OS" = "linux" ]; then
    OS_TARGET="unknown-linux-gnu"
elif [ "$RAW_OS" = "darwin" ]; then
    OS_TARGET="apple-darwin"
else
    echo -e "${RED}[ERROR] Unsupported Operating System: $RAW_OS${NC}"
    exit 1
fi

RAW_ARCH=$(uname -m)

if [ "$RAW_ARCH" = "x86_64" ] || [ "$RAW_ARCH" = "amd64" ]; then
    ARCH_TARGET="x86_64"
elif [ "$RAW_ARCH" = "aarch64" ] || [ "$RAW_ARCH" = "arm64" ]; then
    ARCH_TARGET="aarch64"
else
    echo -e "${RED}[ERROR] Unsupported Architecture: $RAW_ARCH${NC}"
    exit 1
fi

# Expected format: cpython-3.12.6+20240909-x86_64-unknown-linux-gnu-install_only.tar.gz
FILENAME="cpython-${PYTHON_VER}+${RELEASE_TAG}-${ARCH_TARGET}-${OS_TARGET}-install_only.tar.gz"
STANDALONE_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${RELEASE_TAG}/${FILENAME}"

echo -e "${GREEN}[INFO] Target identified: ${ARCH_TARGET} ${OS_TARGET}${NC}"
echo -e "${CYAN}[INFO] Using URL: $STANDALONE_URL${NC}"

echo -e "${CYAN}[INFO] Cleaning up...${NC}"
rm -rf "$WORK_DIR"
rm -f "$DIST_ZIP"

mkdir -p "$WORK_DIR/python"

# Ensure the destination directory actually exists before zipping
DEST_DIR=$(dirname "$DIST_ZIP")
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${CYAN}[INFO] Creating assets directory...${NC}"
    mkdir -p "$DEST_DIR"
fi

echo -e "${CYAN}[INFO] Downloading Portable Python...${NC}"
curl -sSL "$STANDALONE_URL" -o "$WORK_DIR/python.tar.gz"

# Verify download succeeded (Catches 404 errors if a specific version/tag doesn't exist)
if [ ! -s "$WORK_DIR/python.tar.gz" ] || grep -q "Not Found" "$WORK_DIR/python.tar.gz"; then
    echo -e "${RED}[ERROR] Failed to download Python. Verify the version and release tag exist.${NC}"
    rm -f "$WORK_DIR/python.tar.gz"
    exit 1
fi

echo -e "${CYAN}[INFO] Extracting standalone environment...${NC}"
tar -xzf "$WORK_DIR/python.tar.gz" -C "$WORK_DIR/python" --strip-components=1
rm "$WORK_DIR/python.tar.gz"

echo -e "${CYAN}[INFO] Fetching Python License...${NC}"
curl -sSL "https://raw.githubusercontent.com/python/cpython/main/LICENSE" -o "$WORK_DIR/python/LICENSE.txt"

echo -e "${CYAN}[INFO] Installing dependencies...${NC}"
if [ -f "requirements.txt" ]; then
    "$WORK_DIR/python/bin/python3" -m pip install -r requirements.txt --no-warn-script-location
fi

echo -e "${CYAN}[INFO] Copying source files...${NC}"
TARGET_SRC="$WORK_DIR/python/src"
mkdir -p "$TARGET_SRC"
touch "$TARGET_SRC/__init__.py"

for module in analysis data_io plotting cli utils; do
    if [ -d "src/$module" ]; then
        cp -r "src/$module" "$TARGET_SRC/"
    fi
done

# Keep Flutter runtime compatibility
if [ -f "src/cli/main.py" ]; then
    cp "src/cli/main.py" "$WORK_DIR/python/main.py"
fi

if [ -f "src/cli/extract_info.py" ]; then
    cp "src/cli/extract_info.py" "$WORK_DIR/python/extract_info.py"
fi

echo -e "${CYAN}[INFO] Zipping portable environment to $DIST_ZIP...${NC}"
ORIG_DIR=$(pwd)
cd "$WORK_DIR/python" || exit
zip -rq "$ORIG_DIR/$DIST_ZIP" .
cd "$ORIG_DIR" || exit

echo -e "${GREEN}[SUCCESS] Done! Created $DIST_ZIP${NC}"