# The general corpus

Language-agnostic classes of logical flaw worth testing for in any codebase.
This is the top-down companion to the bitten corpus in `SKILL.md`.

## Provenance rule (read this first)

The bitten corpus earns entries from real defects in this work. This file is
different on purpose: each entry is drawn from the broad canon of correctness
flaws, illustrated with a canonical example rather than one that bit us here.

That is a deliberate exception to the "no speculative classes" rule, and it
carries a cost: this list is long, so it is a **filter, not a mandate**. Answer
each trigger against the code in front of you; most will not fire. Do not write
a test per entry.

**Promotion.** The moment one of these bites in this work, move it into the
bitten corpus in `SKILL.md` with the real instance named (file or rule id), and
delete it here. That is how the general list stays a candidate pool and the
bitten list stays evidence.

Two rules from `SKILL.md` still apply to every entry: **red-proof the check**
(ship a positive fixture that fires and a negative that does not), and **a gate
starts green, an inventory starts red**.

Examples are in Python and Bash, the two main languages here. The Python
example uses `pytest`; the Bash example assumes `set -euo pipefail` is the
intended posture unless the entry is about its absence.

---

## 1. Boundary and fencepost

**Trigger:** does anything index, slice, count, or loop over a range? Is there a
first, a last, or a gap-between-items?

**Tier:** 2.

**Test shape:** feed empty, one element, two, and the maximum. Assert the count
of gaps is one less than the count of posts where that is the intent.

**Python:**
```python
def chunks(xs, n):            # off-by-one: drops the tail when len % n
    return [xs[i:i+n] for i in range(0, len(xs) - n, n)]
def test_chunks_keeps_tail():
    assert chunks([1,2,3], 2) == [[1,2],[3]]   # fails: tail lost
    assert chunks([], 2) == []
```

**Bash:**
```bash
# seq 1 $n is n items; a loop "for i in $(seq 1 $((n-1)))" silently skips one.
run() { for i in $(seq 1 "$1"); do echo "$i"; done; }
[ "$(run 3 | wc -l)" -eq 3 ] || echo "FAIL: fencepost"
```

## 2. The empty collection

**Trigger:** does a calculation assume at least one element? A division by a
count, a max/min/first, an average?

**Tier:** 2.

**Test shape:** call it with zero elements. Assert a defined result or a clear
error, never a crash or a silent wrong number.

**Python:**
```python
def mean(xs): return sum(xs) / len(xs)     # ZeroDivisionError on []
def test_mean_empty():
    with pytest.raises(ValueError):        # decide the contract, then pin it
        mean([])
```

**Bash:**
```bash
# "${arr[@]}" with an empty array under set -u expands to an error on old bash.
files=(); count=${#files[@]}
[ "$count" -eq 0 ] && echo "no files" || process "${files[@]}"
```

## 3. An error swallowed

**Trigger:** is there a bare `except`, a `2>/dev/null`, a `|| true`, or a caught
exception with an empty body? Does a failure path return the same shape as
success?

**Tier:** 1 for the syntactic forms; 2 for logic that discards a failure.

**Test shape:** make the guarded operation fail and assert the caller LEARNS of
it. Scan for the swallowing forms and hold at zero where the class is new.

**Python:**
```python
try: n = int(user_value)
except Exception: n = 0        # a bad input now silently means zero
def test_bad_input_is_rejected_not_zeroed():
    with pytest.raises(ValueError): parse("abc")
```

**Bash:**
```bash
rm -rf "$dir" 2>/dev/null || true     # hides a permission error; state is wrong
# instead: rm -rf "$dir" || { echo "cleanup failed for $dir" >&2; exit 1; }
```

## 4. Success assumed: exit status unchecked

**Trigger:** is the return of a call or command used without checking it
succeeded? A pipeline whose middle stage can fail? A `cd` before `rm`?

**Tier:** 1 in Bash (scan for missing `set -e`/`pipefail` and unchecked
`cd`); 2 in Python.

**Test shape:** force the call to fail and assert the program stops or handles
it. In Bash, prove a mid-pipeline failure is caught.

**Python:**
```python
subprocess.run(["build"])          # ignores returncode; a failed build "passes"
r = subprocess.run(["build"]); assert r.returncode == 0, r.stderr
```

**Bash:**
```bash
set -euo pipefail
cd "$build_dir"        # if cd fails without set -e, the next rm runs in $HOME
rm -rf ./out
# test: cd /nonexistent; run script; assert nonzero exit and out/ untouched
```

## 5. Partial failure leaves inconsistent state

**Trigger:** does an operation make several changes that must all land or none?
A loop that writes N files, a multi-row update, a rename-then-write?

**Tier:** 2.

**Test shape:** inject a failure partway and assert the observable state is
either fully-before or fully-after, never half.

**Python:**
```python
for k, v in items: cache[k] = fetch(v)   # fetch raises at item 3 -> half-filled
# fix: build into a fresh dict, swap in only on full success. Test the raise.
```

**Bash:**
```bash
# write to a temp then atomically rename, so a crash never leaves a partial file
tmp=$(mktemp) && generate > "$tmp" && mv "$tmp" "$final"
# test: kill generate mid-run; assert $final is either absent or complete
```

## 6. Float equality and money in floats

**Trigger:** is `==` used on floats? Is currency or a running total held as a
float?

**Tier:** 1 (scan for float `==`); 2 for accumulation error.

**Test shape:** assert with a tolerance, or use integers/Decimal for money. Add
0.1 ten times and assert it is not 1.0 under `==`.

**Python:**
```python
assert 0.1 + 0.2 == 0.3          # False
assert abs((0.1 + 0.2) - 0.3) < 1e-9
from decimal import Decimal; assert Decimal("0.1") + Decimal("0.2") == Decimal("0.3")
```

**Bash:**
```bash
# bash has no floats; awk/bc do. "$(echo "0.1+0.2==0.3" | bc -l)" is 0.
# keep money in integer cents: total=$((a_cents + b_cents))
```

## 7. Integer division and silent truncation

**Trigger:** is a division expected to yield a fraction? Is a value narrowed
(float to int, int64 to int32, large to small)?

**Tier:** 2.

**Test shape:** pick inputs where truncation changes the answer and assert the
intended one.

**Python:**
```python
progress = done / total * 100          # ok in py3; in py2 or with // it truncates
assert 3 // 2 == 1                      # floor, not 1.5 -- is that intended?
```

**Bash:**
```bash
pct=$(( done * 100 / total ))          # integer only: 1/3 -> 0, 2/3 -> 0
# if a fraction matters, use awk: awk "BEGIN{print $done/$total*100}"
```

## 8. Order assumed on unordered data

**Trigger:** does the code iterate a dict/set/map, a glob, `ls`, `find`, or a
DB query with no `ORDER BY`, and then rely on the order?

**Tier:** 2.

**Test shape:** shuffle the input (or run twice) and assert the result is
identical. Sort explicitly where order is load-bearing.

**Python:**
```python
first = list(some_set)[0]              # arbitrary; set order is not insertion order
# test: build the set from two different insertion orders, assert same output
```

**Bash:**
```bash
for f in *.txt; do ...; done           # glob order is locale-sorted, not numeric
# file10 sorts before file2. Use: ls -v or sort -V when numeric order matters
```

## 9. Timezone-naive or DST-blind datetime

**Trigger:** does the code compare, subtract, or add to a datetime? Does it mix
a naive and an aware one, or assume the day is 24 hours?

**Tier:** 2.

**Test shape:** run the logic across a DST boundary and at a non-UTC offset.
Assert the naive/aware mix raises rather than silently comparing wrong.

**Python:**
```python
from datetime import datetime, timezone
datetime.utcnow() < aware_dt           # TypeError or wrong: utcnow() is naive
now = datetime.now(timezone.utc)       # always tz-aware
```

**Bash:**
```bash
date -d "2024-03-10 +1 day"            # a DST day is not +86400 seconds
# test around a known DST switch; assert the wall-clock date, not epoch math
```

## 10. Encoding assumed

**Trigger:** does the code read or write text? Open a file, decode bytes, or
process output that could contain non-ASCII?

**Tier:** 1 in Python (`open`/`read_text` with no `encoding=`).

**Test shape:** feed a byte sequence that is valid UTF-8 but not ASCII, and one
that is invalid, and assert defined behaviour.

**Python:**
```python
open(path).read()                      # uses the platform default encoding
open(path, encoding="utf-8").read()    # explicit; test with "café" and \xff
```

**Bash:**
```bash
# LC_ALL unset makes sort/tr/[[:upper:]] behave differently per machine.
# pin it for deterministic text ops: LC_ALL=C sort
```

## 11. Word-splitting and unquoted expansion

**Trigger:** is a variable that could hold a space, a glob character, or be
empty used unquoted? An array expanded without `[@]` and quotes?

**Tier:** 1 in Bash (shellcheck SC2086 is a scanner for this).

**Test shape:** set the value to `a b`, to `*`, and to empty, and assert the
command sees the intended argument count.

**Python:**
```python
os.system("rm " + name)                # name="a b" deletes two files
subprocess.run(["rm", name])           # one arg, no shell parsing
```

**Bash:**
```bash
cp $src $dst                           # src="my file" becomes two args
cp -- "$src" "$dst"                    # test: src='a b'; assert one file copied
```

## 12. External input trusted

**Trigger:** does user input, a filename, an env var, or network data reach a
shell, a path join, a SQL string, or an eval without validation?

**Tier:** 2.

**Test shape:** feed the hostile case (a `../`, a `;rm`, a `'`, a wildcard) and
assert it is rejected or neutralised, not executed.

**Python:**
```python
open(os.path.join(base, user_name))    # user_name="../../etc/passwd" escapes base
p = (base / user_name).resolve(); assert p.is_relative_to(base.resolve())
```

**Bash:**
```bash
eval "echo $user_input"                # input='; rm -rf ~' runs
# never eval untrusted input; use arrays and quoting. Test with a ';' payload.
```

## 13. TOCTOU: check then act

**Trigger:** does the code test a condition and then act on it as a separate
step? `exists()` then `open()`, `test -f` then read, check-then-create?

**Tier:** 2.

**Test shape:** the race is hard to schedule, so assert the code acts atomically
(open and handle the error) rather than checking first.

**Python:**
```python
if not path.exists(): path.write_text(x)   # racy; two writers both pass the check
path.open("x").write(x)                     # exclusive create; catches the loser
```

**Bash:**
```bash
[ -f "$lock" ] || touch "$lock"        # two runners both see it missing
( set -o noclobber; > "$lock" ) 2>/dev/null || exit 1   # atomic create
```

## 14. Non-idempotent retry

**Trigger:** is an operation retried, re-run, or resumable? Does running it
twice do the thing twice (double-charge, duplicate row, appended line)?

**Tier:** 2.

**Test shape:** run the operation twice and assert the end state equals running
it once.

**Python:**
```python
balance += amount                      # a retry double-applies
# use an idempotency key: if txn_id in applied: return; else apply and record
def test_apply_twice_is_once(): apply(t); apply(t); assert balance == start + amount
```

**Bash:**
```bash
echo "$line" >> "$config"              # re-run duplicates the line
grep -qxF "$line" "$config" || echo "$line" >> "$config"   # test: run twice, wc -l
```

## 15. Resource leak on the error path

**Trigger:** is a file, socket, lock, connection, or temp dir acquired? Does
every path out (exception, early return, break) release it?

**Tier:** 2.

**Test shape:** force an error between acquire and release and assert the
resource is freed (fd count, lock available, temp gone).

**Python:**
```python
f = open(path); data = parse(f); f.close()   # parse raises -> fd leaked
with open(path) as f: data = parse(f)          # released on any exit
```

**Bash:**
```bash
tmp=$(mktemp); work "$tmp"             # work exits nonzero -> tmp orphaned
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT; work "$tmp"   # test: fail work, assert gone
```

## 16. Mutable shared or default state

**Trigger:** is there a default argument that is a list/dict, a module-level
mutable, or a container shared across calls, iterations, or threads?

**Tier:** 1 in Python (scan for mutable default args).

**Test shape:** call the function twice and assert the second call is not
polluted by the first.

**Python:**
```python
def add(x, acc=[]): acc.append(x); return acc   # acc persists across calls
def test_no_shared_default():
    assert add(1) == [1]; assert add(2) == [2]   # fails: second is [1, 2]
```

**Bash:**
```bash
# a global reused across a loop keeps the prior iteration's value on an empty case
for d in "${dirs[@]}"; do count=$(find "$d" -type f | wc -l); report "$d" "$count"; done
# if find fails, count holds the previous $count. Reset: local count=0 each pass.
```

## 17. Empty versus absent conflated

**Trigger:** does a check treat `0`, `""`, `[]`, or `False` the same as missing?
Does it distinguish unset from set-to-empty?

**Tier:** 2.

**Test shape:** pass the falsy-but-present value and the truly-absent value
separately and assert they are handled differently.

**Python:**
```python
timeout = cfg.get("timeout") or 30    # a configured 0 becomes 30
timeout = cfg["timeout"] if "timeout" in cfg else 30
```

**Bash:**
```bash
[ -z "$VAR" ] && VAR=default          # empty and unset both trigger; often wrong
: "${VAR:=default}"                    # :- vs - matters. Test unset vs VAR=""
```

## 18. Comparison on the wrong type

**Trigger:** are two values compared as strings when one means a number, a
version, or a date? Lexicographic where numeric was intended?

**Tier:** 2.

**Test shape:** pick a pair that orders differently as text than as the real
type (`"10" < "9"`, `"1.10" < "1.9"`) and assert the intended order.

**Python:**
```python
sorted(["v10","v2","v1"])             # ['v1','v10','v2'] -- lexicographic
sorted(versions, key=lambda s: tuple(map(int, s.lstrip("v").split("."))))
```

**Bash:**
```bash
[ "$a" -gt "$b" ]                      # numeric; [ "$a" \> "$b" ] is string
# test: a=10 b=9 -- numeric says a>b, string says a<b
```

## 19. Regex over- or under-matching

**Trigger:** is a regex used to validate, extract, or split? Is it unanchored,
greedy, or does it assume `.` spans or stops at newlines?

**Tier:** 2.

**Test shape:** feed a near-miss that should NOT match and a valid multiline
input. Anchor with `^...$` where the whole string must match.

**Python:**
```python
re.match(r"\d+", s)                    # matches "12abc"; match is not fullmatch
re.fullmatch(r"\d+", s)                # test: assert None for "12abc"
```

**Bash:**
```bash
[[ "$ip" =~ [0-9]+\.[0-9]+ ]]          # matches "x1.2y"; unanchored
[[ "$ip" =~ ^[0-9.]+$ ]]               # test with a leading letter; assert reject
```

## 20. Rounding direction and parts of a whole

**Trigger:** is a value rounded, floored, or split into parts that must sum to a
total (percentages, a bill split, pixel widths)?

**Tier:** 2.

**Test shape:** assert the parts sum to the whole and pick a case where naive
rounding drifts (three ways of 100, 1/3 each).

**Python:**
```python
shares = [round(total/3, 2)] * 3       # sums to 99.99 or 100.01, not 100.00
# give the remainder to the last share; test that sum(shares) == total exactly
```

**Bash:**
```bash
each=$(( total / n )); rem=$(( total - each * n ))   # distribute rem explicitly
# test: total=100 n=3; assert each*n + rem == 100 and rem lands somewhere
```

## 21. Non-atomic read-modify-write

**Trigger:** does the code read a value, change it, and write it back, where
another process or thread could interleave? A counter, a JSON state file, a
balance?

**Tier:** 2.

**Test shape:** run two writers concurrently and assert no update is lost
(final == start + 2, not + 1).

**Python:**
```python
state = json.load(open(p)); state["n"] += 1; json.dump(state, open(p,"w"))
# two of these race -> one increment lost. Use a lock or an atomic DB update.
```

**Bash:**
```bash
n=$(cat count); echo $((n+1)) > count  # classic lost update under parallelism
( flock 9; n=$(cat count); echo $((n+1)) > count ) 9>count.lock   # test in parallel
```

## 22. Flaky by time or randomness

**Trigger:** does the code or its test depend on `sleep`, wall-clock time, or an
unseeded random? Does a test pass depend on how fast the machine is?

**Tier:** 2.

**Test shape:** inject the clock and the RNG (or seed them). Assert the same
input gives the same output. A test with a bare `sleep` is the smell.

**Python:**
```python
random.shuffle(xs)                     # unseeded -> non-reproducible test
rng = random.Random(0); rng.shuffle(xs)   # inject seed; assert a fixed order
```

**Bash:**
```bash
sleep 2; assert_ready                  # racy: 2s is a guess, not a condition
# poll the condition instead: for i in {1..50}; do ready && break; sleep 0.1; done
```

## 23. Assuming a single result

**Trigger:** does the code take the first match, `head -1`, `.first()`, or a
single capture, when the source can legitimately return several?

**Tier:** 2.

**Test shape:** supply input with two or more matches and assert the code
handles all of them, or explicitly and correctly picks one.

**Python:**
```python
user = [u for u in users if u.name == n][0]   # IndexError on none, wrong on dupes
matches = [u for u in users if u.name == n]; assert len(matches) == 1
```

**Bash:**
```bash
pid=$(pgrep myapp | head -1)          # silently ignores a second instance
n=$(pgrep -c myapp); [ "$n" -eq 1 ] || { echo "expected 1, got $n" >&2; exit 1; }
```

## 24. CWD or script-location path assumption

**Trigger:** does the code use a relative path, or assume it runs from the repo
root or its own directory? Does it source a sibling file by bare name?

**Tier:** 2.

**Test shape:** run it from a different working directory and assert it still
finds its files.

**Python:**
```python
open("config.yaml")                    # depends on CWD
open(Path(__file__).parent / "config.yaml")   # test: chdir elsewhere, still works
```

**Bash:**
```bash
source ./lib.sh                        # breaks unless run from the script's dir
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); source "$here/lib.sh"
```

## 25. Cleanup missing on failure

**Trigger:** is there setup that must be undone (temp files, a started service,
a lock, a changed setting)? Does the undo run on every exit, including errors
and signals?

**Tier:** 2.

**Test shape:** cause the body to fail and assert the teardown still ran. Also
assert teardown does not run twice or on a setup that never happened.

**Python:**
```python
setup(); body(); teardown()            # body raises -> teardown skipped
try: setup(); body()
finally: teardown()                    # test: make body raise, assert teardown ran
```

**Bash:**
```bash
start_service; run_tests; stop_service # run_tests fails -> service left running
start_service; trap stop_service EXIT; run_tests   # fires on error and Ctrl-C
```

## 26. Boolean config and env parsing

**Trigger:** is a flag read from an env var, a config file, or a CLI string and
then used as a boolean?

**Tier:** 2.

**Test shape:** pass `"false"`, `"0"`, `""`, and unset, and assert each maps to
the intended boolean. The string `"false"` is truthy in most languages.

**Python:**
```python
if os.environ.get("DEBUG"): ...        # DEBUG="false" is truthy -> debug on
debug = os.environ.get("DEBUG","").lower() in ("1","true","yes")
```

**Bash:**
```bash
if [ "$FLAG" ]; then ...               # FLAG="false" passes (non-empty string)
[ "$FLAG" = "true" ] && ...            # test FLAG=false, FLAG=0, FLAG="", unset
```

*(#27 "Silent truncation / partial read" was promoted into the bitten corpus in
`SKILL.md` after it bit a review here; see that file's entry 14.)*
