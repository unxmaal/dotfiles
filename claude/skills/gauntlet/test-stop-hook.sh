#!/usr/bin/env bash
# Red-proof for stop-hook.sh, per the gauntlet's own standing rule: a check
# never observed to fail is not known to work. The negative cases are the point
# -- a hook that fires on every touched file is one that gets switched off.
#
#   ./test-stop-hook.sh
set -uo pipefail
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stop-hook.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
git init -q "$T"; cd "$T" || exit 1
# Session ids must be UNIQUE PER RUN. The first cut reused fixed ids, so the
# dedup state from an earlier run sat in TMPDIR and silenced two cases that had
# passed minutes before on identical code. The test was the thing under test.
RUN="t$$-$(date +%s)"
printf 'def f():\n    """doc."""\n    return 1\n' > mod.py
printf '#!/bin/sh\nset -eu\necho hi\n' > s.sh
git add -A && git -c user.email=t@t -c user.name=t commit -qm base

fails=0
run() { printf '{"cwd":"%s","session_id":"%s","stop_hook_active":%s}' "$T" "$1" "${2:-false}" | "$HOOK" >/dev/null 2>&1; echo $?; }
want() { # want <expected> <got> <name>
  if [ "$1" = "$2" ]; then echo "  ok   $3"; else echo "  FAIL $3: wanted exit $1, got $2"; fails=$((fails+1)); fi
}

want 0 "$(run "$RUN-1")" "a clean tree is silent"

python3 - <<'PY'
from pathlib import Path
p = Path("mod.py"); p.write_text(p.read_text().replace('"""doc."""', '"""a different doc."""'))
PY
want 0 "$(run "$RUN-2")" "a docstring-only change does not fire"

git checkout -q mod.py
printf '#!/bin/sh\nset -eu\n# a new comment\necho hi\n' > s.sh
want 0 "$(run "$RUN-3")" "a comment-only change does not fire"

git checkout -q s.sh
python3 -c "from pathlib import Path; p=Path('mod.py'); p.write_text(p.read_text().replace('return 1','return 2'))"
want 2 "$(run "$RUN-4")" "a real code change fires"

git checkout -q mod.py
printf 'x = 1\n' > new.py
want 2 "$(run "$RUN-5")" "an untracked source file fires"
want 0 "$(run "$RUN-5")" "the same change set does not fire twice in one session"
want 0 "$(run "$RUN-7" true)" "stop_hook_active short-circuits the loop"

echo
[ "$fails" -eq 0 ] && { echo "all cases pass"; exit 0; } || { echo "$fails failing"; exit 1; }
