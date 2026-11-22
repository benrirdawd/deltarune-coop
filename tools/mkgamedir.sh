#!/bin/bash
# Usage: mkgamedir.sh <dest> <chapter> <patched data.win>
# Builds a lightweight game directory of symlinks to the original DELTARUNE
# install, with one chapter's data.win replaced by a patched copy.
# On Windows the links are native symlinks (Developer Mode or admin needed), and DELTARUNE.exe
# is copied, not linked: the test games are then told apart from a normal DELTARUNE by their path.
# Only what is missing or different is touched, so running it while games from the same folder
# start (several sweeps at once) never takes a file away from under them.
set -e
. "$(dirname "$0")/platform.sh"
SRC=$(cd "$DR" && pwd)
DEST=$1; CH=$2; WIN=$(realpath "$3")
link() { [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ] || ln -sfn "$1" "$2"; }
copy() { cmp -s "$1" "$2" 2>/dev/null || { rm -f "$2"; cp "$1" "$2"; }; }
mkdir -p "$DEST"
# The mod's DLLs (mod/dll: Steam play) in the chapter's folder, as the installer puts them.
for d in "$ROOT"/mod/dll/*.dll; do
  [ -f "$d" ] || continue
  mkdir -p "$DEST/chapter${CH}_windows"
  [ "$DEST/chapter${CH}_windows/${d##*/}" -nt "$d" ] || cp -f "$d" "$DEST/chapter${CH}_windows/"
done
# Already built from this install: only the chapter's data.win link can differ. (The full pass costs
# ~10 s in Git Bash, which is slow to start processes; delete <dest>/.built to force it.)
if [ "$(cat "$DEST/.built" 2>/dev/null)" = "$SRC" ]; then
  link "$WIN" "$DEST/chapter${CH}_windows/data.win"
  exit 0
fi
for f in "$SRC"/*; do
  b=${f##*/}
  if [[ "$b" == chapter*_windows ]]; then
    mkdir -p "$DEST/$b"
    for g in "$f"/*; do
      # (Leave other chapters' patched data.win alone: several tests may share this folder.)
      [ "${g##*/}" = data.win ] && [ -e "$DEST/$b/data.win" ] && continue
      # (Leftovers of an installed mod are not part of the game.)
      [[ "${g##*/}" == data.win.vanilla ]] && continue
      # (Windows: settings files are copied, so a test game can never write into the install.)
      if [ -n "$MP_WIN" ] && [[ "$g" == *.ini ]]; then copy "$g" "$DEST/$b/${g##*/}"; else link "$g" "$DEST/$b/${g##*/}"; fi
    done
    # The chapters stream music from mus/ relative to the working directory (the install
    # root when started from the launcher; run_game.sh starts inside the chapter folder).
    link "$SRC/mus" "$DEST/$b/mus"
  elif [ -n "$MP_WIN" ] && { [[ "$b" == *.ini ]] || [ "$b" = DELTARUNE.exe ]; }; then
    copy "$f" "$DEST/$b"
  else
    link "$f" "$DEST/$b"
  fi
done
# If an installed mod left the patched file in the install, the original is data.win.vanilla.
if [ -f "$SRC/chapter${CH}_windows/data.win.vanilla" ]; then echo "note: $SRC/chapter${CH}_windows holds a mod install (data.win.vanilla)" >&2; fi
link "$WIN" "$DEST/chapter${CH}_windows/data.win"
echo "$SRC" > "$DEST/.built"
