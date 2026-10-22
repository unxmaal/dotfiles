---
name: issue-scrutiny
description: Scrutinize and revise one GitHub issue before work starts, the way a top practitioner in its field would. Use after filing an issue and before implementing it, or when asked to review or deepen issues. Edits the issue in place; does not implement it.
---

# Issue scrutiny

An issue is a claim about what is wrong and what would make it right. Most
issues are written from a digest (a summary line, a log grep, an agent's
report) and propose the first fix that comes to mind. The job here is to make
the issue deeper, not bigger: a sharper problem, a better-grounded fix, and an
acceptance test that something other than the author can check.

Run the four questions against the issue, then rewrite it.

## 1. What would a top practitioner do that the issue does not ask for?

Name the field first (evaluation methodology, SRE, data engineering, ML
serving, build systems, statistics). Then ask:
- Is this one instance of a class? Search the store, the logs and closed
  issues for siblings. If the class has more members, the issue covers the
  class, or names the siblings and links them.
- Is the fix treating a symptom? Trace one level up: what decision or
  assumption let this happen, and does the fix change that?
- What would make this class of failure visible next time without a person
  asking? A check, a probe, an audit row, a test that holds at zero.
- Is the proposed scope the smallest change that removes the cause? Cut
  anything that does not serve the acceptance test.

## 2. What is the rawest material?

The issue's evidence must come from primary sources, not digests. Replace any
claim taken from a summary (`soh morning`, a verdict's detail string, an
agent's report, a log grep) with the primary source it summarises:
- rows from a read-only copy of the store, with the SQL;
- the run directory: the model's actual output, patch, trace, stderr;
- full log context around the line, not the matching line alone;
- the code path that produced the value, at the deployed commit;
- the upstream artifact (the HF listing, the git commit, the CI log).
Quote the primary evidence in the issue with the command that retrieves it. If
a claim cannot be traced to primary evidence, mark it as a hypothesis or cut it.

## 3. Which methods and tools?

Name the specific technique, not "investigate". Examples: red-proofed
regression test; fixture of the real failing input; stratified sample with
labels; paired test (McNemar, paired bootstrap) with an interval and a power
estimate; time-in-state from the verdict history; synthetic probe with an
uptime target; known-answer injection (a planted input whose outcome is
fixed); fail-to-pass and pass-to-pass validation; mutation testing. Run the
gauntlet skill's triggers against the proposed fix and name the entries that
fire.

## 4. What, other than the author or the reader, shows the fix is right?

An acceptance criterion an outside check can confirm: a test that fails
before and passes after; a reference answer (gold patch, known-good model,
published score); a planted input reaching its expected verdict; agreement
across machines, platforms or reruns; a store query whose count goes to a
stated value after the next night. "Looks right" and "the agent said so" do
not count.

## Rewrite

Edit the issue in place with `gh issue edit <n> --body-file <file>`:
- **Problem**: primary evidence, quoted, each with the command that
  retrieves it. Siblings in the same class, linked.
- **Cause**: what is known, and what is still a hypothesis.
- **Fix**: the smallest change that removes the cause, plus the check that
  keeps the class visible.
- **Acceptance**: the outside checks from question 4, stated so a stranger
  could run them.
- **Runs at**: day (no GPU) or night (GPU, long runs), and on which machine.
- **Prior art checked**: GitHub issues and KB entries searched, one line.

Keep the house style: no em-dashes, no emojis, no padding. Change the title if
the problem turned out to be different. If the issue should be split, merged
or closed, do that and say why in a comment. Record what the scrutiny changed
in one comment on the issue, so the change is visible in its history.
