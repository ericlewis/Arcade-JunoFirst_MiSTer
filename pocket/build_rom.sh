#!/bin/bash
# Build junofirst.rom from MAME junofrst.zip ROM set
# Usage: ./build_rom.sh /path/to/junofrst/ output.rom

SRC="${1:-.}"
OUT="${2:-../pkg/Assets/arcade/common/junofirst.rom}"

mkdir -p "$(dirname "$OUT")"

cat \
  "$SRC/jfa_b9.bin" \
  "$SRC/jfb_b10.bin" \
  "$SRC/jfc_a10.bin" \
  "$SRC/jfc1_a4.bin" \
  "$SRC/jfc2_a5.bin" \
  "$SRC/jfc3_a6.bin" \
  "$SRC/jfc4_a7.bin" \
  "$SRC/jfc5_a8.bin" \
  "$SRC/jfc6_a9.bin" \
  "$SRC/jfs3_c7.bin" \
  "$SRC/jfs4_d7.bin" \
  "$SRC/jfs5_e7.bin" \
  "$SRC/jfs1_j3.bin" \
  "$SRC/jfs2_p4.bin" \
  > "$OUT"

echo "Created $OUT ($(wc -c < "$OUT") bytes)"
