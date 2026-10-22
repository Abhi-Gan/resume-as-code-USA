# Reference Resume Selection

Past tailored resumes in `data/resumes/` encode style, structure, and voice choices the candidate has already approved (through review/revision cycles in earlier runs). Reusing them as a style reference avoids re-litigating the same phrasing and structural preferences on every new generation.

**Scope of use — style only, never facts.** Reference resumes exist to guide tone, bullet rhythm, level of specificity, and structural conventions. They must never be a source of achievements, numbers, or claims — all factual content still comes exclusively from `data/timeline/*.yml`, scoped to the current JD. A reference resume was tailored for a _different_ job; copying its emphasis or facts into the new resume would misrepresent the candidate for this role.

## Process

1. List all files in `data/resumes/`, excluding the file about to be generated for this run (it won't exist yet, but guard against collisions if re-running for the same JD).
2. **If zero existing resumes**: skip this step entirely. Note in the final report that no reference resumes were available (first-ever generation).
3. **If 1-3 existing resumes total**: use all of them as reference — there's nothing to select between. Skip scoring.
4. **Otherwise, score similarity** of each existing resume against the current Job Analysis (`job-analysis.yml`) and Company Business Analysis. Weigh, in order:
   - Job title similarity (same role family, e.g. "Deep Learning Intern" vs "ML Engineer" vs "Backend SWE").
   - Industry/domain match (e.g. both hardware/AI infra, both fintech).
   - Seniority level match (internship vs new-grad vs mid vs senior).
   - Tech-stack / keyword overlap — compare the reference resume's `skills`/`keywords` fields and Work/Project `keywords` against the current Job Analysis's required stack.
   - Template match (`jake` vs `tech-compact`) as a tie-breaker only, not a primary signal.
5. Rank candidates by aggregate similarity. Select the top 2-3 **only if there's a clear separation** between them and the rest (e.g., the 3rd-ranked resume is meaningfully more similar than the 4th).

## When to ask the user instead of deciding

Do not force a pick when the signal is weak. Ask the user to choose 2-3 reference resumes when any of these hold:

- No existing resume clears a reasonable similarity bar (all are for clearly unrelated roles/industries).
- Scores are tied or too close to call for the 2nd/3rd slot.
- Fewer than 2 resumes are confidently similar, but more than 3 exist (so auto-including "all of them" from step 3 no longer applies).

When asking, present each candidate with enough context to decide at a glance: filename, job title, company, and the specific similarity signals that make it a contender or a toss-up. For example:

> I found several past resumes but couldn't confidently narrow to 2-3 that best match this {JobTitle} at {Company} role. Which should I use as style references (pick 2-3)?
>
> 1. `Abhinav Ganesh_Deep Learning Intern (2027)_NVIDIA.yml` — ML infra internship, similar seniority
> 2. `Abhinav Ganesh_Backend SWE_Stripe.yml` — different domain, same seniority
> 3. `Abhinav Ganesh_Data Scientist_Meta.yml` — different role family, adjacent domain

## After selection

- Read the full YAML of each selected reference resume **once**, here in this step. Save the selection to `data/.cache/<Timestamp>/reference-resumes.yml`:

  ```yaml
  reference_resumes:
    - path: data/resumes/Abhinav Ganesh_Deep Learning Intern (2027)_NVIDIA.yml
      rationale: Same seniority (internship), adjacent ML/infra domain, high keyword overlap.
    - path: data/resumes/...
      rationale: ...
  selection_method: auto | user-selected | skipped-no-history
  ```

- **Do not re-read the reference resume files again later in the run.** Their content is already in your working context from this step — carry it forward mentally into Step 5 (section generation) the same way you already carry forward the Job Analysis and Company Business Analysis. Re-opening the files at each section step (Projects, Work, Skills, Personal Summary) would reload the same content four times for no benefit.
- Apply them as a style exemplar only: mirror bullet opening patterns, how metrics are framed, voice/register, and structural conventions (e.g., how the first bullet folds in keywords for `tech-compact`) — never a specific sentence, achievement, or number from the reference.
