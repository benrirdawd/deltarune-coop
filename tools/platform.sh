#!/bin/bash
# Sourced by the test scripts: everything that differs between Linux (the game under Wine on
# Xvfb displays) and Windows (the native game, scripts run from Git Bash).
#
#   ROOT      the repository
#   DR        the original DELTARUNE install (DELTARUNE_DIR, else $ROOT/DELTARUNE, else
#             D:/Hydra/Deltarune or the Steam folder on Windows)
#   PATCHER   the built drm-patcher
#   PY        python interpreter
#   SAVEDIR   the save folder the test builds use
#   mp_killall [game dir]   stops the test games (on Windows only those started from the game dir)
#   mp_path <path>          the path in a form PY understands
#   mp_kill_pid <pid>       stops one game (its pid as run_game.sh wrote it)
#
# Windows: test builds get their own game name (DRM_SAVE_NAME, default DELTARUNE_MP_TEST), so
# they save to %LOCALAPPDATA%\DELTARUNE_MP_TEST and never touch the real saves and settings.
# Set DRM_SAVE_NAME= (empty) to build with the game's own name.
ROOT=${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) MP_WIN=1 ;; *) MP_WIN= ;; esac

if [ -n "$DELTARUNE_DIR" ]; then DR=$DELTARUNE_DIR
elif [ -d "$ROOT/DELTARUNE" ]; then DR=$ROOT/DELTARUNE
elif [ -n "$MP_WIN" ] && [ -d /d/Hydra/Deltarune ]; then DR=/d/Hydra/Deltarune
elif [ -n "$MP_WIN" ]; then DR="/c/Program Files (x86)/Steam/steamapps/common/DELTARUNE"
else DR=$ROOT/DELTARUNE
fi

if [ -n "$MP_WIN" ]; then
  # Real symlinks (needs Developer Mode or admin), not Git Bash's default of copying.
  export MSYS=winsymlinks:nativestrict
  PATCHER=$ROOT/patcher/bin/out/drm-patcher.exe
  [ -z "$DOTNET_ROOT" ] && [ -x "$HOME/tools/dotnet10/dotnet.exe" ] && export DOTNET_ROOT=$HOME/tools/dotnet10
  export DRM_SAVE_NAME=${DRM_SAVE_NAME-DELTARUNE_MP_TEST}
  PY=python
  SAVEDIR=$(cygpath -u "$LOCALAPPDATA")/${DRM_SAVE_NAME:-DELTARUNE}
  mp_killall() {
    # Only games started from the test folder: a normal DELTARUNE the user has open survives.
    local d; d=$(cygpath -w "${1:-$ROOT/build/game}")
    powershell.exe -NoProfile -Command "Get-Process DELTARUNE -ErrorAction SilentlyContinue | Where-Object { \$_.Path -like '$d\\*' } | Stop-Process -Force" >/dev/null 2>&1 || true
  }
  # One game, by its Windows process id (run_game.sh's MP_PIDFILE).
  mp_kill_pid() { [ -n "$1" ] && taskkill //F //PID "$1" >/dev/null 2>&1; return 0; }
  # Paths handed to (Windows) Python: C:/... instead of /c/...
  mp_path() { cygpath -m "$1"; }
else
  mp_path() { echo "$1"; }
  PATCHER=$ROOT/patcher/bin/out/drm-patcher
  PY=python3
  SAVEDIR=$HOME/.wine-dr/drive_c/users/ai/AppData/Local/DELTARUNE
  mp_killall() { pkill -x DELTARUNE.exe || true; }
  mp_kill_pid() { [ -n "$1" ] && kill "$1" 2>/dev/null; return 0; }
fi
