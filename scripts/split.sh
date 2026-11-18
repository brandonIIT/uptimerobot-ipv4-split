#!/usr/bin/env bash
# Split UptimeRobot's IPv4 list into two halves for SonicOS 6.5 DEAGs.
# Usage: split.sh <raw-input-file>   (writes part1.txt, part2.txt in cwd)
# Exits non-zero (and writes nothing) if the input looks wrong.
set -euo pipefail
in="$1"
tmp=$(mktemp)
tr -d '\r' < "$in" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | sed '/^$/d' > "$tmp"
if grep -qvE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[12][0-9]|3[0-2]))?$' "$tmp"; then
  echo "ERROR: non-IPv4 line(s):"; grep -vE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[12][0-9]|3[0-2]))?$' "$tmp" | head; exit 1
fi
sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n "$tmp" -o "$tmp"
n=$(wc -l < "$tmp")
MIN=60; MAX=106   # 53 per part is the largest size proven to load on Gen 6
if [ "$n" -lt "$MIN" ] || [ "$n" -gt "$MAX" ]; then
  echo "ERROR: $n entries, outside $MIN-$MAX; not updating"; exit 1
fi
half=$(( (n + 1) / 2 ))
head -n "$half" "$tmp" > part1.txt.new
tail -n +"$((half + 1))" "$tmp" > part2.txt.new
mv part1.txt.new part1.txt; mv part2.txt.new part2.txt
rm -f "$tmp"
echo "OK: $n entries -> part1 $(wc -l < part1.txt), part2 $(wc -l < part2.txt)"
