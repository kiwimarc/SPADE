#!/bin/bash

# Configuration
PYTHON_VER="3.12.6"
WORK_DIR="build_temp"
DIST_ZIP="../spade/assets/python_dist.zip"

# Color codes for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Clean Setup
echo -e "${CYAN}[INFO] Cleaning up...${NC}"
rm -rf "$WORK_DIR"
rm -f "$DIST_ZIP"

# Create the work dir
mkdir -p "$WORK_DIR"

# Ensure the destination directory actually exists before zipping
DEST_DIR=$(dirname "$DIST_ZIP")
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${CYAN}[INFO] Creating assets directory...${NC}"
    mkdir -p "$DEST_DIR"
fi

# Download Python Embeddable (Minimal Portable Python)
echo -e "${CYAN}[INFO] Downloading Portable Python ${PYTHON_VER}...${NC}"
URL="https://www.python.org/ftp/python/${PYTHON_VER}/python-${PYTHON_VER}-embed-amd64.zip"
curl -sSL "$URL" -o "$WORK_DIR/python.zip"

mkdir -p "$WORK_DIR/python"
unzip -q "$WORK_DIR/python.zip" -d "$WORK_DIR/python"
rm "$WORK_DIR/python.zip"

# Fetch Python License
echo -e "${CYAN}[INFO] Fetching Python License...${NC}"
curl -sSL "https://raw.githubusercontent.com/python/cpython/main/LICENSE" -o "$WORK_DIR/python/LICENSE.txt"

# Enable Pip (Uncomment 'import site' in python._pth)
PTH_FILE=$(ls "$WORK_DIR"/python/python*._pth | head -n 1)
if [ -n "$PTH_FILE" ]; then
    sed -i 's/#import site/import site/g' "$PTH_FILE"
fi

# Install Pip and Dependencies
echo -e "${CYAN}[INFO] Installing dependencies...${NC}"
curl -sSL "https://bootstrap.pypa.io/get-pip.py" -o "$WORK_DIR/python/get-pip.py"

"$WORK_DIR/python/python.exe" "$WORK_DIR/python/get-pip.py" --no-warn-script-location

if [ -f "requirements.txt" ]; then
    "$WORK_DIR/python/python.exe" -m pip install -r requirements.txt --no-warn-script-location
fi

# Copy project code (new src layout)

# Create the 'src' directory inside the portable python folder
TARGET_SRC="$WORK_DIR/python/src"
mkdir -p "$TARGET_SRC"

# Add an __init__.py so Python treats 'src' as a package
touch "$TARGET_SRC/__init__.py"

# Copy modules INTO the new 'src' directory
for module in analysis data_io plotting cli utils; do
    if [ -d "src/$module" ]; then
        cp -r "src/$module" "$TARGET_SRC/"
    fi
done

# Keep Flutter runtime compatibility: it executes `python.exe main.py`
if [ -f "src/cli/main.py" ]; then
    cp "src/cli/main.py" "$WORK_DIR/python/main.py"
fi

# Optional utility script
if [ -f "src/cli/extract_info.py" ]; then
    cp "src/cli/extract_info.py" "$WORK_DIR/python/extract_info.py"
fi

# Zip it all up
echo -e "${CYAN}[INFO] Zipping portable environment to $DIST_ZIP...${NC}"
ORIG_DIR=$(pwd)
cd "$WORK_DIR/python" || exit
zip -rq "$ORIG_DIR/$DIST_ZIP" .
cd "$ORIG_DIR" || exit

echo -e "${GREEN}[SUCCESS] Done! Created $DIST_ZIP${NC}"