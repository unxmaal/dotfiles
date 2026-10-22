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

## Each half verified against its own spec, the seam against nothing

**Bitten:** 16, all in one afternoon, all in one feature.

**Trigger:** does this change add or alter a boundary between two things that
are built, deployed or run separately? A config value the code must honour. A
producer and a consumer. A program and the environment it runs in. Two
workloads that must agree about something neither declares.

Ask who OWNS the agreement. If the answer is "neither, it is understood", that
is the seam and nothing is testing it.

**Tier:** 2 usually; 1 where one side can be read mechanically from the other,
which is more often than it looks.

**Test shape:** assert the two sides against EACH OTHER, not each against its
own spec. The test must fail when either side changes alone -- that is what
makes it a seam test rather than two more unit tests. Where one side is
machine-readable, scan it: the binaries a program invokes by bare name can be
extracted from the source and checked against the image that runs it.

**Instances,** all from #148 phase 2, each found by running the thing rather
than by reading it:

  the chart declared `parallelism: 4` and the CLI had no sharding, so four
  workers did identical work -- four times the API budget, one result, four
  writers racing on the same rows. The chart claimed a capability the code did
  not have and neither file mentioned the other.

  the sweep wrote 233 proposals and inspect read the crowd instead. Both halves
  worked. The store had no consumer, so the first arrow of the documented
  ladder did not exist.

  the code shells out to `gh` and the image installed `git`. Every candidate
  failed with `[Errno 2] No such file or directory`.

  the token env was on the sweep and not on inspect, so one of two workloads
  that both call GitHub could authenticate -- and it failed QUIETLY, because a
  per-candidate error still exits 0 with an empty result.

**Not the same as two neighbouring entries, and worth keeping apart.** *One
question, two answers* is one value written down twice; here the two sides hold
DIFFERENT things that have to agree. *A reference that no longer resolves* is a
name pointing at nothing; here nothing dangles, the connection is simply absent
and absence has no symptom to find.

## A fact about the harness recorded as a verdict on the subject

**Bitten:** 14 in two days, the most frequent class this corpus has seen.

**Trigger:** does a tier write a TERMINAL verdict (broken, declined, failed)
about the thing under test? Could the same failure come from the harness: a
dead server, a refused request, a runner default, a limit you chose, a missing
download, a name the code could not match?

**Tier:** 2, plus a scanner for the classifier's location (tier 1).

**Test shape:** produce the harness-side failure with a fake (kill the server,
return 400, exhaust the budget you set, ship a README-only snapshot) and assert
the verdict is non-terminal and carries a reason naming the harness. The cause
is a column written where the failure is caught, never a phrase matched later.

**Instances:** localharness 2026-10-05/06: mflux receipt names never matched
(#378), AutoPipeline's table lagged the library (#380), a dead mlx_lm.server
answered "generation thread died" to six later candidates (#404), turbo
sampling defaults refused by a normal model (#401), a 4000-token reasoning
budget and a 180 s cold-load timeout charged to the model (#406), a README-only
snapshot screened as present (#399). Fix shape: verdicts.reason (#408).

## One question, two answers

**Bitten:** 13.

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

## A closed table fronting an open set

**Bitten:** 9.

**Trigger:** is there a dict, enum or if-chain keyed on something an outside
party names (HF tasks, architectures, model families, runtimes, file formats,
error phrases)? What happens to a key nobody listed?

**Tier:** 2.

**Test shape:** feed a key that is not in the table and assert it is refused or
reported as unknown, never silently mapped to the default.

**Instances:** mflux's entry-point table named no discovered repo, so the image
lane could screen nothing (#245, FINDING #159); lane, task and pipeline tables
that dropped new upstream names to a wrong default (#213, #228, #263, #298,
#318, #379, #380, #387; RULE #379, #419).

## A platform primitive assumed universal

**Bitten:** 9.

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

## A guard built and tested that nothing invokes

**Bitten:** 8.

**Trigger:** is there a check, limit or safety function with tests? List its
production callers. Is the risky path among them?

**Tier:** 2.

**Test shape:** drive the risky entry point (not the guard) into the guarded
condition and assert the guard fired.

**Instances:** memory.check_model() had one caller and the screen tier, which
loads arbitrary weights unattended, was not it (#284, FINDING #163, RULE #251);
#1, #137, #143, #172, #182, #191, #279.

## A proxy checked in place of the property

**Bitten:** 7.

**Trigger:** what question does the caller actually need answered? Is the check
answering an easier one: present on disk instead of loadable, process started
instead of serving, a name spelled right instead of behaving right, file size
instead of peak memory?

**Tier:** 2.

**Test shape:** construct a case where the proxy holds and the property does
not (an empty model directory, a server that started and answers nothing) and
assert the check fails.

**Instances:** "present" meant a directory rather than loadable files (#393,
RULE #382); a server that answered /v1/models with an empty body counted as up
(RULE #285); #68, #101, #173, #196, #283, #322, #365.

## A fact recorded without its context

**Bitten:** 6.

**Trigger:** is something stored that is only true on one machine, for one
subject, or on the strength of one piece of evidence? Is that machine, subject
or evidence stored with it?

**Tier:** 2.

**Test shape:** write the fact from one machine or subject and read it from
another; assert the reader cannot mistake it for its own.

**Instances:** a screen verdict carried no receipt (#281); sighting relevance
stored without the machine it applied to (#450); #266, #270, #331, #341
(RULE #293, #356).

## A non-production run writes live state

**Bitten:** 6.

**Trigger:** can a test, a feature branch, a worktree or a scratch run reach the
production store, service or published output? What stops it?

**Tier:** 1 once the live paths are known: a guard on open plus a test that a
non-deploy checkout is refused.

**Test shape:** open the live path from a non-production checkout and assert
refusal; run the suite with HOME pointed at an empty dir and assert nothing
outside it changed.

**Instances:** a worktree migrated the live store (#455, RULE #414); #29, #188,
#290.

## State is whichever row came last

**Bitten:** 5.

**Trigger:** is current state derived from the newest row of an append-only
table? Can any writer append a row that means something different from the
decision it overwrites?

**Tier:** 2.

**Test shape:** append a waypoint row after a terminal decision and assert the
decision still stands; better, keep state in one column with one writer.

**Instances:** inspect re-queued a candidate already declined at adopt, because
"the latest verdict is what every tier reads" (#393, #399, RULE #382, #389);
#225, #253, #254. Fixed structurally by proposals.state with one writer (#409).

## An input accepted and silently ignored

**Bitten:** 5.

**Trigger:** does a flag, parameter, config key or fetched field get parsed and
then never reach the code that would act on it?

**Tier:** 1 where an AST scan can find parameters never read; 2 otherwise.

**Test shape:** pass two different values and assert the output differs; pass
an unknown one and assert it is refused.

**Instances:** a json_schema sent through LiteLLM to mlx-lm, which has no
constrained decoding, was ignored with no error (FINDING #186); #60, #103, #215,
#315, #329 (RULE #355).

## A metric quoted without a negative control

**Bitten:** 5, and the most expensive per occurrence.

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

## A consumer limits before it filters for what it can act on

**Bitten:** 5.

**Trigger:** is there a `[:n]`, `LIMIT`, or top-N taken from a ranked list, and
THEN a filter for "ready", "in this lane", "not yet measured"?

**Tier:** 2.

**Test shape:** put the only actionable row below the cut and assert it is
still acted on.

**Instances:** the screen took the rank head of candidates the fetch had
skipped for budget, so six fresh downloads were never screened (#376); the
measure step and external discovery did the same (#386); a lane scope applied
after sampling (#209).

## Identity by name, not by content

**Bitten:** 5, inside the machinery built to prevent exactly its own class of
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

## A rule change leaves old decisions standing

**Bitten:** 4.

**Trigger:** does this fix change how decisions are made? What happens to the
decisions already recorded under the old rule?

**Tier:** 2.

**Test shape:** seed a decision made under the old rule, apply the change, and
assert it is re-evaluated or explicitly grandfathered with a reason.

**Instances:** verdicts that a corrected screen would have reversed stayed
terminal (#230, #295, #301, RULE #333); #73.

## One column, two meanings

**Bitten:** 4.

**Trigger:** does one field hold different kinds of value depending on the row
(a path here, content there; a download dir for one tier, a receipt for
another; a timestamp or a sentinel)?

**Tier:** 2.

**Test shape:** for each kind of row, assert every reader gets the kind it
expects; a scan that only one module reads the legacy field.

**Instances:** results.artifact held a file path for image lanes and the output
TEXT for svg/web, so the judge server opened an SVG document as a filename and
showed nothing (#461, #463); verdicts.run_path meant a download dir at fetch and
a receipt at screen (#411).

## A confounded experiment: the label is not the run

**Bitten:** 4.

**Trigger:** does an experiment compare configurations by name? Did anything
verify that the configuration labelled is the one that executed?

**Tier:** 2.

**Test shape:** assert the run's own provenance matches its label. Trace where
each input actually came from rather than trusting the parameter you passed.

**Instance:** three crowd configurations labelled "1 hop", "2 hops" and "2 hops
/ 450" produced identical hop compositions, so the conclusion drawn from them
described an experiment that never ran (RULE #215).

## A test that bounds a measured duration

**Bitten:** 5.

**Trigger:** does a test compare an elapsed time (perf_counter, time.time,
a measured wait or TTFT) against a number? Is any of that time spent in
something the test does not control: interpreter startup, a sleeping fake,
the scheduler under parallel workers?

**Tier:** 2. A scanner for `perf_counter() - ` beside `<` or `>=` in tests
would find the sites but cannot tell a meaningless-generous bound from a tight one.

**Test shape:** assert what the duration stood for. Order (acquired after
released, reasoning before answer), counts (peak in-flight requests), lower
bounds that a slow machine cannot break, or a structural fact (the holder is
still alive). Keep a time bound only if it is loose enough to mean "did not
hang".

**Instances:** a held-lock refusal timed under 1.0 s, 2.85 s on Windows CI
(RULE #533). Best-of concurrency timed under 0.9 s, 0.9004 on macOS CI (#819).
First-token arrival bounded above, under load 14 (#833). A lock wait bounded
below, eaten by the taker's interpreter startup under 30 workers (#772).
A sleep(1.0) used to order two batches, overtaken by a fresh store's
migrate under load, so the second took the lease first (#844).

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

## A shared fixed resource in tests

**Bitten:** 3, all surfacing only when agents ran suites in parallel.

**Trigger:** does a test bind a fixed port, use a fixed launchd label, lock
file, temp path, or service name?

**Tier:** 1.

**Test shape:** run the suite twice concurrently; assert both pass. Ask the OS
for the resource (bind port 0, pid-suffixed labels).

**Instances:** services tests on 49221-49223 (#426); the launchd probe label
(#437); and the same shape outside tests: two background watchers whose
`pgrep -f` matched each other's command lines and deadlocked for 40 minutes
(RULE #384).

## A fake that does not model the real process's environment

**Bitten:** 3, all on Windows CI.

**Trigger:** does a test stand in for a subprocess, server or CLI with a fake?
Does the fake inherit the platform's defaults (stdio encoding, exec bit,
shebang) where the real one sets its own?

**Tier:** 2. Whether a fake matches the real process depends on how the code
under test launches it, so a repo-wide scan could only check a proxy (SoHoT
PR #515).

**Test shape:** launch fakes via sys.executable, set their stdio to the real
tool's encoding explicitly, and run the suite on the platform with the
hostile default.

**Instances:** a fake nimble scorer executed as a script (WinError 193, #454);
a fake `claude` child echoing in cp1252 (#473); fixtures building cached repos
as empty directories, which encoded the bug the code was fixed for (#399).

## One default tuned for one member applied to all

**Bitten:** 3.

**Trigger:** was a default (context size, timeout, memory budget, sampling
setting) measured on one model or one machine and then applied to every member
of an open set?

**Tier:** 2.

**Test shape:** assert the default is computed per member from that member's
own facts, with two members whose correct values differ.

**Instances:** one 16384-token context for every GGUF, so Ornith failed every
long-context agent case (#498); #355, #401.

## A test double that never reaches the code under test

**Bitten:** 3, all invisible: every test stayed green while patching nothing.

**Trigger:** does a test monkeypatch or mock a name? Is that the binding the
code under test actually reads, or a re-export, an alias, or a module the
reader imported the value from before the patch ran?

**Tier:** 1. An AST scan can resolve each patch target to the module whose code
reads the name (SoHoT tests/test_module_layout.py patch-target guard).

**Test shape:** assert the patched value is what the code under test observed,
not only that the test passed; scan every patch target against its readers.

**Instances:** patching `evals.run.capture` never reached
`memory_store.this_machine()`, so tests probed the real machine (#517);
`base.score` and `chain.stage_unavailable` patched on modules that do not read
them (#518, #519); the #484 split's guard found about 80 more that a module
move would have broken silently.

## A constant chosen before the thing it constrains existed

**Bitten:** 3.

**Trigger:** does this change add or keep a module-level number that decides a
pass, a verdict or a cutoff (a token budget, a timeout, a ceiling, a
threshold), picked before the model, lane or machine it limits was measured?

**Tier:** 1.

**Test shape:** register it with the range to sweep, the lanes it affects and
the limit it records when it binds. A repo-wide scan holds new unregistered
gating constants at zero. Count the recorded limit per lane so a binding knob
is reported and swept rather than silently shaping results.

**Instances:** a 4000-token reply budget made 72% of a reasoning model's code
failures look like wrong answers (#628, RULE #535); a memory ceiling derived,
never measured (#96); a TTS runaway cutoff never tested against real speech
(#91).

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

## A transport change that silently changes the payload

**Bitten:** 1, caught by a real check, not a test.

**Trigger:** did a change alter HOW a request is made (streaming, batching, a
proxy hop, compression, a new client library) for a path whose OUTPUT includes
more than the text: logprobs, usage, headers, tool calls?

**Tier:** 2.

**Test shape:** for every field a consumer reads, assert it survives the new
transport end to end through the real proxy, not just a fake.

**Instance:** time-to-first-token made every request stream (#473); LiteLLM
drops logprobs from streamed replies, so the decide lane would have scored
every gateway model one-hot with no error (#489, RULE #426).

## History reconstructed from present state

**Bitten:** 1.

**Trigger:** does a migration or backfill re-derive a past decision? Does it
read the record of that decision, or today's disk, config or adoptions?

**Tier:** 2.

**Test shape:** migrate a historical store on a machine whose present state
differs from the past (no weights, different adoptions) and assert the
backfilled decision matches its receipt.

**Instance:** pre-24 adoptions backfilled to whatever spec was on disk at
migration time, found by the golden stores (#506, RULE #292).

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
