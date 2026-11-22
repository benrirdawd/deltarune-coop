"""Keeps, in a chapter's battle list (work/sweep/enc_chN.txt), only the encounters the chapter's own
code refers to; the rest are numbers left over in scr_encountersetup from other chapters, with
enemies this chapter doesn't have (they always crash, alone as well, and the game never starts them).

Usage: encused.py <chapter>...
Needs the chapter's code exported: drm-patcher --export-code <data.win> work/chN/AllCode.
The full list is kept as work/sweep/enc_all_chN.txt (and read from there next time).

An encounter counts as used when anything outside scr_encountersetup names it: an assignment
(encounterno / myencounter = N), a check (encounterno == N), scr_battle(N, ...) or the dojo table.
That keeps a few that are never really reached (e.g. 4, obj_chaseenemy's default number, or
the ones enemies check for), which is the safe side: those still run and, if they crash alone too,
are reported as the game's own.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATTERNS = [r"\b(?:encounterno|myencounter)\s*=\s*(\d+)\s*;", r"\bencounterno\s*==\s*(\d+)",
            r"\bscr_battle\(\s*(\d+)", r"\bdojoEncounter\[\d+\]\s*=\s*(\d+)"]

for ch in sys.argv[1:]:
    code = os.path.join(ROOT, f"work/ch{ch}/AllCode")
    files = [f for f in glob.glob(os.path.join(code, "*.gml")) if "scr_encountersetup" not in f]
    if not files:
        sys.exit(f"chapter {ch}: no exported code in {code}")
    used = {0}
    for f in files:
        text = open(f, encoding="utf-8", errors="ignore").read()
        for p in PATTERNS:
            used |= {int(x) for x in re.findall(p, text)}
    full = os.path.join(ROOT, f"work/sweep/enc_all_ch{ch}.txt")
    out = os.path.join(ROOT, f"work/sweep/enc_ch{ch}.txt")
    if not os.path.exists(full):
        os.replace(out, full)
    enc = [int(l.split()[1]) for l in open(full) if l.strip()]
    keep = [e for e in enc if e in used]
    open(out, "w").write("".join(f"enc {e}\n" for e in keep))
    print(f"chapter {ch}: {len(keep)} of {len(enc)} encounters kept; left out: {' '.join(str(e) for e in enc if e not in used)}")
