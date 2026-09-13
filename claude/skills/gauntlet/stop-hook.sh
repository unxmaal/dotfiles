#!/usr/bin/env bash
# Gauntlet Stop hook. At end of turn, if the turn changed source CODE, force one
# continuation so the agent runs the gauntlet across the diff before the turn ends.
# Fail-open: any error exits 0 and never traps the agent (cf. RULE #61 / FINDING #98).
set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Loop guard: once we have already forced a continuation this turn, allow the stop.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
{ [ -n "$cwd" ] && [ -d "$cwd" ]; } || exit 0
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Source files touched in this working tree (staged, unstaged, or untracked).
candidates="$(git -C "$cwd" status --porcelain --untracked-files=all 2>/dev/null \
  | awk '{print $NF}' \
  | grep -Ei '\.(py|sh|bash)$' \
  | sort -u || true)"
[ -n "$candidates" ] || exit 0

# Keep only files whose CHANGE touched something other than comments and
# docstrings. Matching on extension alone fired this hook on a one-line
# docstring citation, which is a checklist firing where it has nothing to say --
# the exact way a check earns its way into being switched off.
#
# Fail-open in both directions that matter: an untracked file has no diff and
# always counts, and an unreadable diff keeps the file rather than dropping it.
changed=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if ! git -C "$cwd" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    changed="${changed}${f}"$'\n'
    continue
  fi
  touched="$(git -C "$cwd" diff HEAD -U0 -- "$f" 2>/dev/null \
    | grep -E '^[+-]' \
    | grep -Ev '^(\+\+\+|---)' \
    | sed -E 's/^[+-][[:space:]]*//' || true)"
  if [ -z "$touched" ]; then
    changed="${changed}${f}"$'\n'
    continue
  fi
  # A line that is blank, or opens with a comment or a triple quote, is prose.
  code="$(printf '%s\n' "$touched" | grep -Ev '^([#]|"""|'\''\'\'''\''|$)' || true)"
  [ -n "$code" ] && changed="${changed}${f}"$'\n'
done <<EOF
$candidates
EOF
changed="$(printf '%s' "$changed" | sed '/^$/d')"
[ -n "$changed" ] || exit 0

# Remind once per distinct change set per session, so it does not nag every turn.
# The key carries the REPO as well as the session. Keyed on the session alone,
# one session working in two checkouts silenced the hook in the second, and a
# reused id silenced it entirely -- which is how the red-proof below first
# "passed" and then failed on identical code, with the difference living in a
# leftover file in TMPDIR.
sid="$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null || echo nosession)"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$cwd")"
key="$(printf '%s\n%s' "$sid" "$root" | shasum 2>/dev/null | awk '{print $1}' || printf '%s' "$sid")"
sig="$(printf '%s' "$changed" | shasum 2>/dev/null | awk '{print $1}' || true)"
state="${TMPDIR:-/tmp}/gauntlet-stop-${key}"
if [ -n "$sig" ] && [ -f "$state" ] && [ "$(cat "$state" 2>/dev/null || true)" = "$sig" ]; then
  exit 0
fi
[ -n "$sig" ] && printf '%s' "$sig" >"$state" 2>/dev/null || true

count="$(printf '%s\n' "$changed" | grep -c . || true)"
files="$(printf '%s\n' "$changed" | head -12 | sed 's/^/  - /')"
{
  echo "[gauntlet] This turn changed ${count} source file(s). Before ending, apply the gauntlet across them:"
  echo "$files"
  [ "$count" -gt 12 ] && echo "  ... (${count} total)"
  echo "For each changed file, answer the triggers in ~/.claude/skills/gauntlet/SKILL.md (the bitten corpus). Where a trigger fires, add or update a test in its test shape and red-proof it. If none fire, say which files you checked and that none fired, then stop."
  echo "general-corpus.md is for sweeping a whole codebase, not a diff: reach for it when reviewing an unfamiliar repo or a large change, not because this fired."
} >&2
exit 2
