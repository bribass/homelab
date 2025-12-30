#! /bin/bash

BASEDIR=$(dirname $0)
SVG=$1

if [ "X$SVG" == "X" ]; then
  echo "SVG icon filename not specified.  Aborting." >&2
  exit 1
fi

set -e

# Create a temporary work directory
WORK=$(mktemp -d "${TMPDIR:-/tmp/}svgXXXXXX.iconset")
if [ ! -d "$WORK" ]; then
  echo "Could not create temoporary directory.  Aborting." >&2
  exit 2
fi
function cleanup {
  rm -rf "$WORK"
}
trap cleanup EXIT

# Convert SVG to PNG images of required sizes
for i in 16 32 64 128 256 512; do
  magick -density 300 -background none $SVG -resize $i "$WORK/icon_${i}x${i}.png"
  magick -density 300 -background none $SVG -resize $(($i * 2)) "$WORK/icon_${i}x${i}@2x.png"
done

# Assemble final ICNS file
OUT=$(mktemp "${TMPDIR:-/tmp/}$(basename $SVG .svg)_XXXXXX.icns")
icnsutil -c icns -o $OUT $WORK >/dev/null 2>&1
if [ ! -f "$OUT" ]; then
  echo "Could not convert to icon file.  Aborting." >&2
  exit 3
fi
echo -n $OUT
