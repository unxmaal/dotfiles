---
name: gauntlet
description: The corpus of high-level logical failures that have actually bitten this work, each with a trigger question and a test shape. Use when designing tests for new or changed code, when reviewing a diff, before opening a PR, or after a defect is found, to derive the general violation behind it and add it here.
---

# The gauntlet

A test written for one piece of code cannot be reused on another. The
**violation behind it** can. Trace a defect up until the specificity falls away
and what is left applies to code nobody has written yet.

This file is that corpus. It grows. Every entry earned its place by actually
happening.

The out-of-sample audit that tests whether these classes have power on code
they were not derived from lives in the localharness repo as `harness/audit.py`,
not here: it needs tests and CI, and a second copy of it in this directory would
be the *one question, two answers* entry below, committed against this file.

A companion file, `general-corpus.md`, holds a top-down list of language-agnostic
flaw classes drawn from the broad canon rather than from a defect here, each with
a Python and a Bash example. It is a candidate pool: the moment one of those
bites in this work, it graduates into THIS file with the real instance named, and
is deleted there. Read it when sweeping a whole codebase or a large diff; read
this file first, because these entries carry the higher signal.

## How to run it

For each entry below, answer its **trigger** against the code in front of you.
Most will not fire. For the ones that do, instantiate the **test shape**.

Do not write a test for every entry. A checklist that always fires produces
twenty pointless tests per module and gets switched off within a week, which is
the same failure mode as a scanner that flags everything.

## The three tiers, and why the distinction matters

**Tier 1 — scanner.** One test, written once, covers every file in the repo
including the ones not written yet. Build the scanner and stop thinking about
the class *in that repo*.

It does not leave this file, though, and the earlier wording promising that was
wrong: this corpus is user-level and the scanner is per-repo. A tier 1 entry is
really the question "does THIS repo have the scanner yet", which is why running
the corpus against a second codebase is worth doing even when every entry is
tier 1 and every one is solved somewhere else. Class *a platform primitive
assumed universal* had a scanner in one repo and three live defects in the next.

**Tier 2 — per-site.** Cannot be generalised to a scan; must be instantiated
wherever the trigger fires. This is the gauntlet proper.

**Tier 3 — review question.** Cannot be mechanised at all. A test claiming to
check it would pass while the thinking was still wrong. Ask it out loud, and
record the answer where the claim is made.

When an entry can be promoted from tier 2 to tier 1, promote it: it converts a
recurring judgement into a one-off build. The file still grows, and that is
correct — it is a record of what has actually gone wrong, and that only
accumulates. What must not grow is the number of entries a reader has to think
about on a small diff, which is what the triggers are for.

## Two rules that apply to every entry

**Red-proof the check.** A check never observed to fail is not known to work.
Every scanner ships with a positive fixture proving it fires and a negative one
proving it does not fire on innocent input. The negative case is not the
formality: `is_prose` and the privacy scanner were both caught by theirs.

**A gate starts green; an inventory starts red.** If the class is already
violated in fifty places, the check is an inventory and must not block. If it
is violated nowhere, wire it into lint and hold it at zero, because holding
zero costs nothing. Deciding which one you have is part of writing it.

---

# The corpus

Ordered by how often each has actually bitten, so the order MOVES whenever a
count does.

**Cite an entry by its name, never by its position.** These were numbered once,
and the numbers were already wrong: a test in another repo cited "class 11" and
a rule cited "class 3" for entries that had since moved. That is entry *identity
by name, not by content* below, committed inside the corpus that names it.

## One question, two answers

**Bitten:** 6.

**Trigger:** is this value, list, or policy written down in more than one
place? Shell and Python. Code and config. Code and a case file. Two configs.

**Tier:** 1 where the copies can be parsed; 2 otherwise.

**Test shape:** read both copies from source and assert they agree. Parse
rather than import, so the test does not depend on the other side's
dependencies being installed. Then add a row to a **census** listing every
known instance, so the pattern is visible in one place: the first five were
each filed as unrelated bugs because nobody could see they were one thing.

**Instances:** an HF candidate list forked into `env.sh` and `env.py`. An MSYS
path spelled two ways. `env.sh` overwriting an `HF_HOME` that `env.py`
respected. `PLAYERS` in shell and Python. `lh image` running 1024 while every
eval case pinned 512. Lane defaults naming gateway aliases nothing checked.

## A platform primitive assumed universal

**Bitten:** 5.

**Trigger:** does this call a shell command by bare name, touch file modes,
read or write text, or format a path?

**Tier:** 1. Nearly all of these are scannable.

**Test shape:** scan every source file for the unguarded form. Prefer an AST
scan to a grep: it sees a multi-line call and can tell a literal binary mode
from a text one.

**Instances:** `read_text()` with no `encoding=`, caught by this repo's own
portability scan. A bare `bash` that resolved to WSL on the Windows runner and
answered in UTF-16. `chmod(0o500)` used to remove write access, where the
Windows equivalent is an ACL. A BSD-only `df` flag in a POSIX script. Three
unencoded `open()` calls in mcm-engine, found by running this entry and closed
with a gate that holds at zero (RULE #244).

## A metric quoted without a negative control

**Bitten:** 4, and the most expensive per occurrence.

**Trigger:** does anything rank, score, or judge? Does a number get compared to
another number to support a conclusion?

**Tier:** 2.

**Test shape:** score two known-DIFFERENT things and two known-SAME things.
Assert the gap between classes exceeds the spread within a class. Pin the
control's outcome in a test so it cannot silently stop being true.

**Instances:** speaker similarity quoted at 0.878 vs 0.781 when two genuinely
different men scored 0.827, so the metric separated nothing (NEGATIVE #9). A
rubric that scored six unrelated candidates 10/10 after being shown the inspect
verdict (RULE #211). A control that gave gap +4 and +2 on identical inputs
because nothing pinned a seed, making every "SEPARATES" verdict one draw from a
distribution (RULE #217). Co-star ranking, where the positive control passing
was the reason to read further down the list.

## A number without its configuration

**Bitten:** 4.

**Trigger:** does prose state a number a reader will act on?

**Tier:** 1. A scanner can find a number in prose whose neighbourhood says
nothing about when, on what, at what size, or with which tool.

**Test shape:** flag a number in a comment or markdown with no nearby date,
resolution, machine, quantisation or instrument. Expect a large backlog, so
ship it as an inventory. Carve out the sharp subset that starts empty and gate
that: a cost quoted beside the command that incurs it.

**Instance:** two correct measurements looked like a regression because neither
carried its resolution, producing two wrong issues (RULE #238).

## A part's cost reported as the whole's

**Bitten:** 3.

**Trigger:** is a cost, latency or size being published? Is it the cost of the
component, the phase, or the thing the user actually waits for?

**Tier:** 1 when the claim sits beside an invocation; 2 otherwise.

**Test shape:** measure at the user-facing entry point, not the stage. Then
assert no published cost sits beside a command with its conditions unstated.

**Instances:** "costs about 2s a line" was the fixed per-call overhead, when
four words cost 4.4s and twenty-eight cost 11.3s. "Kokoro, sub-second" is
plausibly true of the synthesis and false of the command, at 3.5s.

## A check whose input differs between the desk and CI

**Bitten:** 2. The second came twenty minutes after building the fix for the
first.

**Trigger:** does this check enumerate files? Does it ask the filesystem, or
`git ls-files`, or anything else that differs between a working tree and a
fresh clone?

**Tier:** 1.

**Test shape:** resolve against what a push would publish, meaning tracked plus
untracked-and-not-ignored. Then a test proving a file written just now is
visible, and that an ignored file is not. Where prose legitimately names
something that does not ship, enumerate the exceptions with the step that
creates each, and assert each exception is still genuinely absent: an allowlist
that outlives its reason is how a check rots.

**Instances:** a privacy scanner green locally and red on three runners on the
same commit, because a detector's fixtures are by definition examples of what
it detects (RULE #231). A prose-reference test using `Path.exists()`, passing
on the machine that had built a gitignored binary and failing everywhere else.

## A format assumed to generalise

**Bitten:** 2.

**Trigger:** is a syntax being used in a list, a batch, or a delimiter-joined
form, on the assumption that the single form extends?

**Tier:** 3, unless the tool has a dry-run.

**Test shape:** verify the batch form against the tool's actual behaviour once,
then encode the safe form as the convention.

**Instance:** `Closes #a, #b, #c` in a PR body. GitHub honours only the first
reference. It stranded seven issues, there was already a rule about it, and it
happened again three weeks later. One `Closes #n` per line.

## A confounded experiment: the label is not the run

**Bitten:** 2.

**Trigger:** does an experiment compare configurations by name? Did anything
verify that the configuration labelled is the one that executed?

**Tier:** 2.

**Test shape:** assert the run's own provenance matches its label. Trace where
each input actually came from rather than trusting the parameter you passed.

**Instance:** three crowd configurations labelled "1 hop", "2 hops" and "2 hops
/ 450" produced identical hop compositions, so the conclusion drawn from them
described an experiment that never ran (RULE #215).

## External state with no assertion on it

**Bitten:** 2. The second was found by running this corpus, which makes it the
first entry here the gauntlet turned up rather than a person.

**Trigger:** does anything here depend on someone else's version, image, path
or published artifact? Is it true, dated, load-bearing and unwatched?

**Tier:** 1.

**Test shape:** assert the external fact in the job that depends on it, and
make the failure message name what the claim was load-bearing FOR and both ways
out. An assertion that only says "this changed" makes the next person re-derive
the decision.

**Instances:** `ubuntu-latest` is 24.04, and CI parity with it was the entire
reason that distro was chosen. Nothing would have noticed the label moving.
Sixteen gateway aliases naming somebody else's published weights, with nothing
asserting any of them is obtainable: four had already been proven wrong by hand
on a bare machine, and the issue had been open a day with no general fix.

**What the second instance added to the test shape:** an identifier that does
not say WHERE it comes from cannot be checked by anyone, and that missing
provenance is the defect rather than a symptom of it. Nine aliases carried full
repo ids and were verifiable; seven carried a bare filename stem and were not.
So the check has an offline half asking whether a thing is checkable AT ALL,
which needs no network and catches the real problem, and a network half that
only runs where the first half passes.

## A statistic blind to the effect under test

**Bitten:** 2, and both times the null result was read as evidence.

**Trigger:** is a summary statistic standing in for the thing being measured?
What can this statistic NOT see? A count cannot see order. A mean cannot see
spread. A top-1 cannot see anything below it.

**Tier:** 3. This one cannot be automated and should not pretend to be.

**Test shape:** none. Ask the question before running the experiment, and if
the statistic is blind to the effect, a null result is uninformative rather
than negative.

**Instance:** a decay parameter reported inert because hits, leaks and top[0]
did not move. All three are insensitive to ordering by construction, and the
ordering was what had changed: 10 of the top 15 positions differed.

## Identity by name, not by content

**Bitten:** 1, inside the machinery built to prevent exactly its own class of
error.

**Trigger:** does a comparison, cache key, dedup or equality check use an
identifier? What can change while the identifier does not?

**Tier:** 2.

**Test shape:** edit the content, hold the id fixed, assert the check notices.
Fix with a digest over the parts that change the meaning, compared only when
both sides carry one, so existing records stay valid.

**Instance:** a comparability check that refused to rank runs across every axis
that changes the exam, and compared case *ids*. Rewriting a case in place kept
its id, its count and its receipt.

## A failure mode inferred, not observed

**Bitten:** 1, and it was self-confirming.

**Trigger:** is a claim being made about how a system fails? Was it read from
the system, or reasoned out?

**Tier:** 2.

**Test shape:** a test that PRODUCES the failure. If it cannot be produced, the
claim is wrong.

**Instance:** "concurrent SQLite writers corrupt the file." They serialise, and
the error is `database is locked`. The two have opposite fixes. Worse, the
connection set no `busy_timeout`, so a second writer really did fail at once
and the wrong diagnosis looked confirmed.

## A reference that no longer resolves

**Bitten:** 1, found on the test's first run.

**Trigger:** does documentation name files, symbols or commands?

**Tier:** 1.

**Test shape:** every repo-relative path in prose must reach a reader. A bare
path means this repo; a foreign one carries its repo in front of it.

**Instance:** a plan citing another project's `scripts/eval/model_registry.py`
by bare path, which reads as a local file.

## Silent truncation, or a partial read assumed complete

**Bitten:** 1, and it was the review itself, not the code under review.

**Trigger:** does anything read a fixed number of bytes, take a `LIMIT`, cap a
buffer with `head`/`tail`, or assume one read returns the whole thing? Is a
short or empty result then read as "absent" or "done"?

**Tier:** 2.

**Test shape:** feed input larger than the cap and assert nothing load-bearing
is lost, or that the truncation is intended and announced. For a scan that
answers a yes/no question, put the evidence PAST the cap and assert it is still
found — a check that reads too few lines fails open, silently.

**Instance:** while running this corpus against mcm-engine, `grep`-ing `head -3`
of three shell scripts to decide whether they carried `set -euo pipefail`. The
line sits below the comment header, so the truncated read returned nothing and
was taken as "the guard is absent." It produced a false finding that was acted
on until a full read refuted it (RULE #244). Promoted here from the general
corpus, which is where it first lived as a candidate.

---

# Adding an entry

After any defect, ask what CLASS of reasoning made it possible, and add the
class rather than the instance. A new class that bit here goes in this file; a
class promoted up from `general-corpus.md` moves here and leaves there.

An entry needs six fields. The **violation** as the heading, in one line.
**Bitten**, the count of real occurrences, which is what the ordering sorts on.
**Trigger** as a question answerable about code you are looking at, which is
what turns this from a mandate into a filter. **Tier**. **Test shape**. **At
least one real instance**, named, with the file or rule id. (An entry in
`general-corpus.md` carries no bite count and a canonical example instead of a
named instance; that is the one difference between the two files.)

Do not add speculative classes. An entry with no instance is how a checklist
becomes noise, and noise is how the whole file stops being read.

When an entry has bitten again, increment **Bitten** and move the entry to its
new place. Keep the count a bare integer: the ordering is the only affordance
for a reader who will not read all fourteen, so it has to be sortable rather
than prose. `5+` is a shrug, and it was in here until a review counted the
instances and found four.

Never reintroduce entry numbers. The order moves, numbers imply identity, and
citations outside this file went stale within a day of the first ones.

The durable record of each instance belongs in the knowledge base via
`add_rule` or `add_negative`. This file is the loading mechanism: it puts the
corpus in front of you at the moment tests are being designed, which is exactly
the moment nobody thinks to search for it.
