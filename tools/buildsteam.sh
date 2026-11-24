#!/bin/bash
# Usage: buildsteam.sh   Builds mod/dll/drm_steam.dll (steam/drm_steam.c, the Steam play extension)
# with Zig (ZIG=path, default ~/tools/zig-*/zig). Valve's steam_api64.dll goes next to it as
# drm_steam_api64.dll: it is already in mod/dll; STEAM_API=path replaces it (Steamworks SDK 1.57+,
# e.g. from a Steamworks.NET release).
. "$(dirname "$0")/platform.sh"
ZIG=${ZIG:-$(ls -d "$HOME"/tools/zig-*/zig* 2>/dev/null | grep -E 'zig(\.exe)?$' | head -1)}
[ -x "$ZIG" ] || { echo "zig not found (set ZIG)"; exit 1; }
mkdir -p "$ROOT/mod/dll"
"$ZIG" cc -shared -O2 -target x86_64-windows-gnu -o "$ROOT/mod/dll/drm_steam.dll" "$ROOT/steam/drm_steam.c" -lshell32 || exit 1
rm -f "$ROOT/mod/dll/drm_steam.lib" "$ROOT/mod/dll/drm_steam.pdb"
[ -n "$STEAM_API" ] && cp "$STEAM_API" "$ROOT/mod/dll/drm_steam_api64.dll"
[ -f "$ROOT/mod/dll/drm_steam_api64.dll" ] || echo "warning: no mod/dll/drm_steam_api64.dll (set STEAM_API)"
echo "mod/dll: $(ls "$ROOT/mod/dll" | tr '\n' ' ')"
