#!/usr/bin/env bash
# Manage opt-in modules under modules/. See modules/README.md.
#   module list            list modules + installed status
#   module add <name>      copy a module's files into the repo
#   module remove <name>   remove the files a module added
set -u

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
MODROOT="modules"
CLAUDE_MOD="claude/modules"

usage() { sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; }

mod_installed() {
    local name="$1" f rel
    [ -f "$CLAUDE_MOD/$name.md" ] && return 0
    f="$(find "$MODROOT/$name/files" -type f 2>/dev/null | head -1)"
    [ -n "$f" ] || return 1
    rel="${f#"$MODROOT/$name"/files/}"
    [ -e "$rel" ]
}

cmd_list() {
    local d name about status
    for d in "$MODROOT"/*/; do
        [ -d "$d" ] || continue
        name="$(basename "$d")"
        about=""; [ -f "$d/about" ] && about="$(head -1 "$d/about")"
        if mod_installed "$name"; then status="[installed]"; else status="[          ]"; fi
        printf '  %-16s %s %s\n' "$name" "$status" "$about"
    done
}

cmd_add() {
    local name="$1" src="$MODROOT/$1" f rel
    [ -d "$src" ] || { echo "no such module: $name"; return 1; }
    if [ -d "$src/files" ]; then
        cp -a "$src/files/." ./
        while IFS= read -r f; do
            rel="${f#"$src"/files/}"; chmod +x "$rel" 2>/dev/null || true
        done < <(find "$src/files" -name '*.sh' -type f)
    fi
    if [ -f "$src/claude.md" ]; then
        mkdir -p "$CLAUDE_MOD"; cp "$src/claude.md" "$CLAUDE_MOD/$name.md"
    fi
    echo "added module: $name"
    [ -f "$src/notes.md" ] && { echo; cat "$src/notes.md"; }
}

cmd_remove() {
    local name="$1" src="$MODROOT/$1" f rel
    [ -d "$src" ] || { echo "no such module: $name"; return 1; }
    if [ -d "$src/files" ]; then
        while IFS= read -r f; do
            rel="${f#"$src"/files/}"; rm -f "$rel"
        done < <(find "$src/files" -type f)
    fi
    rm -f "$CLAUDE_MOD/$name.md"
    echo "removed module: $name (your edits to other files untouched)"
}

case "${1:-list}" in
    list)    cmd_list ;;
    add)     shift; [ $# -ge 1 ] || { usage; exit 2; }; for m in "$@"; do cmd_add "$m"; done ;;
    remove)  shift; [ $# -ge 1 ] || { usage; exit 2; }; for m in "$@"; do cmd_remove "$m"; done ;;
    -h|--help) usage ;;
    *) echo "unknown command: $1"; usage; exit 2 ;;
esac
