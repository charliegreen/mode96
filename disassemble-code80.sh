#!/bin/bash

INF="_gen_/font.inc"
OUT="${1:-code80.s}"
if [[ -z "$1" ]]; then
    echo "Notice: no filename provided, assuming 'code80.s'"
fi

TMP="$(mktemp)"

# get the right parts of the file
sed -n '/^const char font\[\]/,/^};/ p' "$INF" | tail -n+2 | head -n-1 |
    
    # uncomment, normalize whitespace/commas into spaces, create binary
    sed 's|//.*$||' | tr -s '\n ,' ' ' | xxd -r -p - "$TMP"

if avr-objdump -m avr -b binary -D "$TMP" > "$OUT"; then
    # echo "Successfully disassembled '$INF'!"
    :
fi

rm "$TMP"

