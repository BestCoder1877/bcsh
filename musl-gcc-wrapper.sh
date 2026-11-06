#!/bin/sh
name=$(basename "$0")
real="$(dirname "$0")/${name}-real"
crt1=$("$real" -print-file-name=crt1.o)
crti=$("$real" -print-file-name=crti.o)
crtn=$("$real" -print-file-name=crtn.o)
crtbegin=$("$real" -print-file-name=crtbeginS.o)
crtend=$("$real" -print-file-name=crtendS.o)
tmp=$(mktemp)
for arg in "$@"; do
    case "$arg" in
        crt1.o) arg=$crt1 ;;
        crti.o) arg=$crti ;;
        crtn.o) arg=$crtn ;;
        crtbegin.o|crtbeginS.o) arg=$crtbegin ;;
        crtend.o|crtendS.o) arg=$crtend ;;
        -lunwind) arg=-lgcc_eh ;;
        -Wl,-lunwind) arg=-Wl,-lgcc_eh ;;
    esac
    printf '%s\n' "$arg" >> "$tmp"
done
set --
while IFS= read -r arg; do set -- "$@" "$arg"; done < "$tmp"
rm -f "$tmp"
exec "$real" "$@"
