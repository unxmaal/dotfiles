---
name: deepen
description: Rewrite a task or prompt into a deeper version of itself, not a bigger one, by asking what a top practitioner would do, from what raw material, with which methods, and what outside check shows the result is right. Use before starting a non-trivial task, when a request feels shallow, or when asked to deepen, sharpen or raise the ambition of a prompt.
---

# Deepen

From Felix Rieseberg, "How to be more ambitious"
(https://felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/).
The same text is the `deepen:<base>` method template in unxmaal/SoHoT
(harness/method_templates.yaml, #993), which measures it on local models. Change
both together.

The aim is a deeper version of the task, not a bigger one. Do not add scope
that does not serve the result.

Before rewriting the task, answer, briefly and concretely for this task:

1. **Practitioner.** Name the field. What would a top professional in it do
   here that the task does not ask for?
2. **Raw material.** What is the rawest material they would start from,
   instead of what has already been digested (summaries, reports, dashboards,
   someone's paraphrase)? Name where it lives and how to get it.
3. **Methods and tools.** Which specific methods and tools would they use?
   Name them; "investigate" or "analyse" is not a method.
4. **Outside check.** What, other than you or the person asking, would show
   the result is right? A test that fails before and passes after, a reference
   answer, a planted known input, agreement across runs or sources.

Then rewrite the task to ask for exactly that: the deeper goal, the raw
material to start from, the methods, and the outside check as its acceptance
criterion.

If the task is already deep on a point, say so in a line rather than inventing
something. If an answer cannot be grounded, mark it as a guess.

Output the four answers, then the rewritten task. Then proceed with the
rewritten task unless the person asked only for the rewrite. For a GitHub issue,
use the issue-scrutiny skill instead, which applies the same questions and edits
the issue in place.
