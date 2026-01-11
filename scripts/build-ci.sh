#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Build started"

# Setup Emscripten SDK
log "Cloning emsdk..."
git clone https://github.com/emscripten-core/emsdk.git
log "Installing emsdk..."
cd emsdk
./emsdk install latest
log "Activating emsdk..."
./emsdk activate latest
source ./emsdk_env.sh
cd ..
log "Emscripten setup complete"

# Build WASM
log "Configuring WASM build..."
cmake --preset wasm-release
log "Building WASM..."
cmake --build --preset wasm-release
log "WASM build complete"

# Build Playground (Vite)
log "Installing npm dependencies..."
cd playground
npm install
log "Building Vite project..."
npm run build
cd ..
log "Playground build complete"

# Copy to dist/
log "Copying to dist/..."
mkdir -p dist
cp -r playground/dist/* dist/
cp build/wasm-release/*.wasm dist/
cp build/wasm-release/*.js dist/

log "Build finished"
