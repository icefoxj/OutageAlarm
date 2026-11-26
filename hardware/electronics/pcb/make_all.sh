#!/bin/bash
# Builds and checks the whole PCB from board.py: project, schematic, board, ERC, DRC (with schematic parity),
# the kit checks, pictures, schematic PDF, Gerbers, drill files, the Gerber zip and the BOM.
# Run it in Git Bash (Windows) or on Linux, from any folder. KiCad 8 is looked for in its standard places on C:
# and D:; set KICAD_BIN to its bin folder if it is somewhere else. PYTHON (default: python) is the plain Python
# for the scripts that don't need pcbnew. Adapted from DiceTester's placa/scripts/gerar_tudo.sh.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
for KB in "$KICAD_BIN" "/c/Program Files/KiCad/8.0/bin" "/d/Program Files/KiCad/8.0/bin" "/usr/bin"; do
    if [ -n "$KB" ] && { [ -x "$KB/kicad-cli.exe" ] || [ -x "$KB/kicad-cli" ]; }; then KICAD_BIN="$KB"; break; fi
done
CLI="$KICAD_BIN/kicad-cli"; [ -x "$CLI.exe" ] && CLI="$CLI.exe"
KPY="$KICAD_BIN/python"; [ -x "$KPY.exe" ] && KPY="$KPY.exe"; [ -x "$KPY" ] || KPY=python3
PY="${PYTHON:-python}"
export PYTHONUTF8=1 KICAD_BIN
K="$HERE/../kicad"; OUT="$HERE/../fabrication"; G="$OUT/gerber"; IMG="$HERE/../../../docs/img"
NAME=OutageAlarm
VERSION=$("$PY" -c "import sys; sys.path.insert(0, r'$HERE'); import board; print(board.VERSION)")
BASE="$OUT/${NAME}_pcb_v${VERSION}"
mkdir -p "$OUT"

"$PY" "$HERE/make_project.py"
"$PY" "$HERE/make_schematic.py"
"$KPY" "$HERE/make_pcb.py"
"$CLI" sch erc --severity-all --exit-code-violations --format json -o "$OUT/erc.json" "$K/$NAME.kicad_sch"
"$CLI" pcb drc --severity-all --schematic-parity --exit-code-violations --format json -o "$OUT/drc.json" "$K/$NAME.kicad_pcb"
"$KPY" "$HERE/check_pcb.py" "$K/$NAME.kicad_pcb"
"$KPY" "$HERE/render_pcb.py" "$K/$NAME.kicad_pcb" "$IMG"
"$CLI" sch export pdf -o "${BASE}_schematic.pdf" "$K/$NAME.kicad_sch"

# fabrication: Gerbers (no paste layers: the board is all through-hole), drill files, the zip for the maker
rm -rf "$G" && mkdir -p "$G"
"$CLI" pcb export gerbers --use-drill-file-origin --layers F.Cu,B.Cu,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts \
    -o "$G/" "$K/$NAME.kicad_pcb"
"$CLI" pcb export drill --format excellon --drill-origin plot --excellon-separate-th -o "$G/" "$K/$NAME.kicad_pcb"
(cd "$G" && rm -f "${BASE}_gerbers.zip" && \
 "$PY" -c "import sys, zipfile; z = zipfile.ZipFile(sys.argv[1], 'w', zipfile.ZIP_DEFLATED); [z.write(f) for f in sorted(sys.argv[2:])]; z.close()" \
   "${BASE}_gerbers.zip" *.gtl *.gbl *.gto *.gbo *.gts *.gbs *.gm1 *.drl *.gbrjob)
"$PY" "$HERE/make_bom.py" "${BASE}_bom.csv"
ls -la "$OUT"
