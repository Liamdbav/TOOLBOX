#!/bin/bash
# Usage: ./resize.sh <fichier_source> <dossier_output>

src="$1"
out_dir="$2"
base=$(basename "$src" | sed 's/\.[^.]*$//')  # nom sans extension
ext="${src##*.}"

mkdir -p "$out_dir"

for size in 16 48 128; do
  sips -Z $size "$src" --out "$out_dir/${base}_${size}.${ext}"
done
