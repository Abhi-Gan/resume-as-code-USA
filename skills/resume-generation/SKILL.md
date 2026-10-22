---
name: resume-generation
description: Generate a highly targeted YAML resume from a Job Description. Use when the user provides a JD (job description, job posting, job ad, role description) and asks for a tailored resume, an updated resume, a resume polish, or a resume that matches the role.
---

# Resume Generation

Produce one tailored resume in YAML for a single Job Description, by combining the candidate's master timeline with JD-specific analysis. The result is placed under `data/resumes/`, alongside a matching Typst stub file (see step 10) — that stub, not the YAML, is what actually gets compiled to a PDF.

This skill only supports the Typst rendering pipeline. There is no Legacy/YAMLResume/LaTeX path anymore — both the old React/Puppeteer app and the LaTeX escape hatch have been fully retired. Every resume is New Schema v1.0 YAML, rendered by a template under `templates/`.

## When to trigger

Activate when the user supplies a Job Description (raw text, a link, or a file path) and asks for a resume, a tailored resume, or a resume for that role.

## Inputs you must read

- `data/profiles/basics.yml`
- `data/profiles/education.yml`
- `data/profiles/certificates.yml`
- `data/profiles/writing-style.md` (optional — personal phrasing preferences; skip silently if absent, since this file is per-user and not everyone using this repo will have one)
- `data/profiles/generation-preferences.yml` (optional — personal defaults for the startup prompt below, e.g. preferred research depth or template; skip silently if absent and fall back to this skill's hardcoded defaults. Not for phrasing — that's `writing-style.md`.)
- All files under `data/timeline/*.yml`
- The user-provided JD
- Existing files under `data/resumes/` (as style reference — see step 4)

## Outputs you will produce

- Intermediate artifacts in `data/.cache/<UTC-Timestamp>/` (one per generation run).
- Final resume in `data/resumes/{CandidateName}_{JobTitle}_{Company}.yml`.
- A matching Typst stub, `data/resumes/{CandidateName}_{JobTitle}_{Company}.typ` (see step 10).

## Review & Revision Options

**Sourcing defaults**: before presenting the prompt below, check whether `data/profiles/generation-preferences.yml` was found in the Inputs step. Any field it sets overrides that option's hardcoded default shown in brackets below; fields it omits keep the hardcoded default. This file only changes what counts as "default" — the prompt is still shown every run so the user can override per-generation.

**Discover available templates** before presenting the prompt below: list the subdirectories of `templates/` that contain an `adapter.typ` (currently `tech-compact`, `zhiweio`). This is the complete, only set of valid template options — it grows automatically as templates are added under `templates/<name>/`; never hardcode it.

**Two different kinds of "which template" rules exist in this document — don't conflate them:**

- **Mechanical/pipeline rules** (which stub to generate, what import path it uses, how paper size is set, how validation runs) apply to **any** discovered template uniformly — this is template-agnostic infrastructure, substitute whichever name was chosen.
- **Content-structure rules** (no standalone Skills section, no personal summary, one-page hard cap, Experience/Research split) are specific to templates that share the original Tech-Compact content convention. Currently that's `tech-compact` and `zhiweio` (`zhiweio` was built to replicate the same source design) — referred to below as **Tech-Compact-style templates**. A future template could legitimately want a Skills section and personal summary; don't assume every template follows this convention by default.

Before starting the pipeline, present the user with these options:

1. **Research depth** — how much external company/tech research to do in steps 2-3? (default: `full`, options: `full` / `light` / `skip` — see routing under step 2)
2. **Auto review + revise** — should the pipeline automatically review and revise the resume after De-AI? (default: `yes`)
3. **Revision rounds** — how many review-revise cycles to run? (default: `1`, options: `1` / `2` / `3`)
4. **Template** — which visual template should this resume use? (default: `tech-compact`, options: the discovered `templates/` list)

Present as a single prompt (substituting any overridden defaults from `generation-preferences.yml`, and the discovered template list from above):

> Resume generation pipeline ready. Quick setup:
>
> 1. Research depth? [full/light/skip] (default: full)
> 2. Auto review & revise after generation? [Y/n]
> 3. Review-revise rounds? [1/2/3] (default: 1)
> 4. Template? [tech-compact/zhiweio] (default: tech-compact)

If the user does not respond, use the (possibly overridden) defaults. Store the answers in the run context for steps 2, 3, 5, 6, and 10.

## Workflow

### 1. Initialize a run directory

Create `data/.cache/<UTC-Timestamp>/` (e.g. `data/.cache/20260608_104500/`). All intermediate artifacts for this run go here.

### 2. Analyze the company and business context

**Routed by the `research_depth` answer from the startup prompt:**

- **`full`** (default): Follow [references/company-business-analysis.md](references/company-business-analysis.md) in full. Use DeepWiki, Context7, and Web Search as directed in the reference to build a complete picture of the company's business lines, strategic direction, tech stack, and the business unit this role supports. Save the result to `data/.cache/<Timestamp>/company-business-analysis.yml`.
- **`light`**: Follow the same reference, but skip DeepWiki and Context7 and run at most one `WebSearch` (company overview + a sanity check against the JD's claims). Skip the `jd_gaps` deep-dive research; fill it only from what's directly inferable by comparing the JD to that one search's results. Save the (shorter) result to the same path.
- **`skip`**: Do not run this step. No company-business-analysis file is produced; downstream steps treat it as absent.

This output, when produced, is **required input** for the next step.

### 3. Analyze the JD

Follow [references/job-analysis.md](references/job-analysis.md). Save the result to `data/.cache/<Timestamp>/job-analysis.yml`. The `language` field detected here governs the entire downstream pipeline.

**Routed by the same `research_depth` answer:**

- **`full`**: consume the company business analysis from step 2 as primary context, and research the technical landscape (Context7, DeepWiki, WebSearch) as directed in the reference.
- **`light`**: consume the (lighter) company business analysis from step 2, but skip the technical-landscape research sweep — rely on existing knowledge of named technologies instead of looking them up.
- **`skip`**: no company business analysis exists. Work directly from the raw JD text and existing knowledge, with no external tool calls. Still produce every field in the output format, but any field that normally depends on business-context inference (e.g. `hidden_requirements`, the business-framing parts of `candidate_profile`) should be filled conservatively from the JD alone, or omitted rather than guessed.

When a company business analysis exists, its output includes a `rewritten_jd` field that is sharper and more honest than the raw HR posting, and the resume generation steps target that rewritten JD, not the original. In `skip` mode there is no rewrite pass beyond what `job-analysis.md` itself produces from the JD directly.

### 4. Gather context, match timelines, and select reference resumes

- Read all files in `data/timeline/`.
- Select the work and project entries most relevant to the Job Analysis and Company Analysis. Filter out clearly irrelevant ones; prioritize the rest.
- **Project priority confirmation**: if the candidate has more than two viable projects, ask the user to nominate up to two priority projects. If the user does not specify, auto-select the two best flagship projects based on JD relevance, business impact, quantified outcomes, technical depth, architectural ownership, and complementarity.
- **Non-selected projects are still mined for signal**: any unselected project that contains JD-relevant capability, domain experience, architecture, or delivery outcomes must contribute those signals into the generated Work Experience or Skills section so they are not lost.
- **Resume length budget**: optimize for focus and scannability, ideally fitting within **two pages**. Preserve complete chronology, but compress older roles and non-flagship project detail before trimming the two highlighted projects.
- **Name localization**: if a school or organization name is stored in bilingual form `English | 中文`, output only one side based on target language — Chinese side for `zh`, `zh-hans`, `zh-hant-hk`, `zh-hant-tw`; English side for `en`, `es`, `fr`, `no`. Do **NOT** output both names in a monolingual resume.
- **Select reference resumes for style consistency**: follow [references/reference-resume-selection.md](references/reference-resume-selection.md) to pick 2-3 existing resumes from `data/resumes/` most similar to this JD, or ask the user if the choice is ambiguous. Save the selection to `data/.cache/<Timestamp>/reference-resumes.yml`. These are style/structural exemplars only, read once here and carried forward mentally into step 5 — never re-read them per section, and never source facts from them.

### 5. Generate all sections in one combined pass

Read [references/overview.md](references/overview.md) and all four section references below **before drafting anything**. Then draft Projects, Work, Skills, and Personal Summary as **one continuous generation pass**, not four separate turns — later sections must see and stay consistent with the sections drafted earlier in this same pass, since Skills is derived from the Work/Projects you just wrote and Personal Summary is derived from all three (see `overview.md`'s Generation Workflow & Context).

**Before writing a single bullet**: if `data/profiles/writing-style.md` exists (read in the Inputs step above), apply its rules to every bullet across all sections below — as you draft, not as a cleanup pass afterward. Skip a rule for a specific bullet if applying it would produce an awkward or unclear sentence, or would conflict with another rule in this document (e.g. the no-fabrication or humanizer rules). This is in addition to, not a replacement for, mirroring the reference resumes' structural conventions.

Hold Job Analysis (including `language`), Company Business Analysis, the matched context, and the reference resumes selected in step 4 (if any) as shared context for the whole pass — do not re-fetch them per section.

Each section uses array `summary: []` syntax (each bullet as a separate string, never a pipe-string `|` block). Each item must include an `id` field. Reference `assets/section-{name}.example.yml` for structure.

Draft in this order, within the single pass:

1. **Projects** — see [references/section-projects.md](references/section-projects.md). At most **two** highlighted projects.
2. **Work Experience** — see [references/section-work.md](references/section-work.md). Must stay consistent with the Projects just drafted: don't restate a flagship project's achievements under Work — absorb signal from the *un*selected projects instead (per the reference's Project-to-Work Synthesis rule).
3. **Skills** — see [references/section-skills.md](references/section-skills.md). Extract this section from the Work and Projects content just drafted, so keyword claims stay aligned with what the resume actually demonstrates elsewhere — do not re-derive it independently from raw timeline data. **Style reset — do not carry over momentum from steps 1-2**: Skills bullets must NOT be quantified (no numbers, percentages, or KPI-style phrasing), which is the opposite of the Work/Projects rule immediately above. **Skip this step entirely for Tech-Compact-style templates** (`tech-compact`, `zhiweio`) — these have no standalone Skills section; the same keyword signal is folded into each Work/Project entry's first bullet instead (see section-work.md / section-projects.md's Tech-Compact rules).
4. **Personal Summary** — see [references/section-personal-summary.md](references/section-personal-summary.md). Synthesize from the Projects, Work, and Skills just drafted so the summary reflects the tailored resume. **Skip this step entirely for Tech-Compact-style templates** — these have no personal summary section at all.

**Save each section to its own file** under `data/.cache/<Timestamp>/`: `section-projects.yml`, `section-work.yml`, `section-skills.yml`, `section-personal-summary.yml`. One drafting pass produces four separate artifacts, so step 6 (and any later ad hoc regeneration of a single section) can still target one file directly.

Detailed length budgets, ATS rules, supported Markdown subset, and authenticity rules live in [references/overview.md](references/overview.md) — this is the file you already read at the top of this step; it also has a **Template-Specific Rules** section covering Tech-Compact-style templates' one-page hard cap and bullet conventions.

### 6. Assemble the final resume

Merge into one YAML file. Use [assets/resume.example.yml](assets/resume.example.yml) as the structural template — do not copy its content. Sources:

- `data/profiles/basics.yml` (basics — merge the generated summary into `basics.summary`, unless using a Tech-Compact-style template, in which case leave `basics.summary` empty/omitted since step 5 skipped generating one)
- `data/profiles/education.yml` — if an entry has a distinct `gpa` field, pass it through as `gpa` on the assembled education item. Tech-Compact-style templates' Typst adapters render this on its own row when present. If the source only has GPA embedded in `summary` prose (older profile data), leave it as-is; this isn't a required migration.
- `data/profiles/certificates.yml`
- `data/.cache/<Timestamp>/section-{personal-summary,skills,work,projects}.yml` — for Tech-Compact-style templates, `section-personal-summary.yml` and `section-skills.yml` won't exist (step 5 skipped them); only merge `section-work.yml` and `section-projects.yml`.

**Profiles (social links)**: always include `profiles` from `data/profiles/basics.yml` if present (e.g. GitHub, LinkedIn).

**Top-level structure**: `schema` → `document` → `basics` → `order` → `sections`.

- `schema.version`: `"1.0"`
- `document.title`: `"{JobTitle} – {Company}"`
- `document.language`: from Job Analysis `language` field. Supported: `en`, `zh-hans`, `zh-hant-hk`, `zh-hant-tw`, `es`, `fr`, `no`.
- `basics`: name, headline, phone, email, url, summary (as `string[]`), profiles
- `order`: `["education", "work", "skills", "certificates", "projects"]` — for Tech-Compact-style templates, drop `"skills"` from this list (no standalone Skills section exists for these templates).
- `sections`: array of discriminated section objects, each with `id`, `type`, `items`

**`layout` block**: write `layout: { template: <chosen-name> }`, using whichever template name was chosen at startup. Paper size is not set here — it's a Typst theme default in that template's `templates/<name>/adapter.typ`, not a content field. Do not add a `page:` sub-block; it's not read by anything.

**Experience/Research split** (Tech-Compact-style templates): if the candidate's matched work entries include both industry roles and academic/research roles, split them into two separately-titled `work`-type sections instead of one — e.g. `{ id: work, type: work, title: Experience, items: [...] }` and `{ id: research, type: work, title: Research, items: [...] }`, both listed in `order` adjacent to each other. This is valid today because sections are keyed by `id`, not `type` — two sections can share `type: work`.

**Profiles placement**: `profiles` appears under `basics.profiles`.

**Summary format**: all `summary` fields must be `string[]` (each bullet as a separate string). Do NOT use pipe-string `|` syntax.

**Section order** (via top-level `order` array):

```
education → work → skills → certificates → projects
```

Each section object must include `id` (matching the order value) and `type` (one of: `work`, `education`, `projects`, `skills`, `certificates`). Each item within a section should include an `id` field.

### 7. De-AI the resume text

After assembling the YAML, run a humanizer pass to strip AI writing patterns from all free-text fields. This step makes the resume read as human-written.

**Select the humanizer based on `language`** from Job Analysis:

| Language codes                              | Humanizer reference                                      |
| ------------------------------------------- | -------------------------------------------------------- |
| `en`, `es`, `fr`, `no`                      | [references/humanizer-en.md](references/humanizer-en.md) |
| `zh`, `zh-hans`, `zh-hant-hk`, `zh-hant-tw` | [references/humanizer-zh.md](references/humanizer-zh.md) |

**Fields to process** (string values only — never touch keys, dates, URLs, or structure):

- `basics.summary`
- Each work entry's `summary` and `highlights[]`
- Each project entry's `summary` and `highlights[]`
- Skills group `summary` (if present)
- Any `description` fields

`summary` fields are `string[]`. Process each array element independently — each element is a single bullet string. Edit the array elements in place, preserving the array structure.

**Constraints**:

- Preserve YAML validity — edit string values in place.
- Rewrites must be the **same length or shorter**, never longer.
- The resume is professional register; skip personality/soul injections.
- No em dashes (—) or en dashes (–) in the final output.
- Save the humanized YAML back to the same file, overwriting the pre-humanized version.

### 8. Review the resume

Follow [references/resume-review.md](references/resume-review.md). Read the De-AI'd resume YAML, `job-analysis.yml`, and `company-business-analysis.yml`. Save the review output to `data/.cache/<Timestamp>/resume-review.yml`.

The review produces a structured YAML analysis covering first impression, deep audit (holistic + per-section), revision blueprint, and final verdict. **This audit is always full and holistic** — every round re-audits the whole resume, never just the sections a prior round changed, regardless of how the routing below plays out.

**Routing**:

- **Auto mode** (user chose auto review+revise at startup): continue directly into step 9 in the same pass — do not stop and start a new turn. There is no user decision gating this, so review and revision are one continuous pass; only the artifacts (`resume-review.yml`, then the revised resume) are still saved as separate files.
- **HITL mode**: stop here. Present the review summary (final_verdict + summary counts) and ask:

  > Review complete. Score: {score}/100 | Issues: {total} ({fail} critical, {warn} warnings). Would you like to revise? [y/N]

  If the user declines, skip step 9 and proceed to step 10.

### 9. Revise the resume (optional)

If revision was selected (auto or HITL-confirmed):

Follow [references/resume-revision.md](references/resume-revision.md). Read `resume-review.yml` and the current resume YAML. Produce the revised resume and overwrite the assembled YAML file. Per that reference, only the sections listed in `resume-review.yml`'s `summary.sections_needing_revision` are modified — every other section is copied verbatim.

**Scoped De-AI after revision**: run the humanizer pass (step 7 rules) only on the fields belonging to the sections in `summary.sections_needing_revision` — the same sections revision just touched. Do not re-run it over the whole resume: sections outside that list were left untouched by revision and already passed humanization in an earlier pass (step 7, or a prior round's step 9), so reprocessing them is redundant. The humanizer selection (English vs Chinese) is the same as step 7.

**Multi-round loop**: after the scoped humanizer pass, if more rounds remain (based on startup option), loop back to step 8 for another full review pass. Each round's review is saved as `resume-review-round{N}.yml` in the same cache directory.

```
Round 1: review (full) -> revise (scoped) -> humanize (scoped)
Round 2: re-review (full) -> revise (scoped) -> humanize (scoped)
Round 3: re-review (full) -> revise (scoped) -> humanize (scoped, final)
```

After the final round (or if user declines revision), proceed to step 10.

### 10. Name and save the final file

- **File path**: `data/resumes/{CandidateName}_{JobTitle}_{Company}.yml`
  - `CandidateName` — from `data/profiles/basics.yml` (`basics.name`).
  - `JobTitle` — from Job Analysis (`title`).
  - `Company` — from Job Analysis (`company`).
  - Join with underscores `_`. **Preserve spaces inside each part** (do not replace spaces within a name/title/company with underscores).
- Save the assembled YAML.
- **Typst stub** — written to `data/resumes/{CandidateName}_{JobTitle}_{Company}.typ`, alongside the YAML. The import path is derived from the chosen template name (`layout.template`), not hardcoded:
  - **If the stub doesn't exist yet** (first generation of this resume), create it fresh:

    ```typst
    #import "../../templates/{chosen-template-name}/adapter.typ": render
    #let data = yaml("{CandidateName}_{JobTitle}_{Company}.yml")
    #render(data)
    ```

  - **If the stub already exists** (this is a revision pass on an existing resume): leave it alone. Do not regenerate or overwrite it. It may contain hand-tuned `theme: (...)` overrides (font size, spacing, margin) from a prior fitting pass — these must never be silently clobbered. The one exception: if `layout.template` in the YAML has changed since the stub was last written, patch only the `#import` line to match the new template's adapter path, and say so explicitly to the user — do not touch anything else in the file (the `theme:` block, if present, stays exactly as it was).
  - If a resume runs long (doesn't fit the one-page hard cap after content trimming), proactively tell the user you can tighten it by nudging `font-size`, `spacing`, or `margin` in the stub's `theme:` block — do not build this as a UI control, just offer it conversationally and make the edit if they agree.

- **Validate**: run a clean compile as the correctness check —

  ```bash
  typst compile --root . "data/resumes/{CandidateName}_{JobTitle}_{Company}.typ" /dev/null
  ```

  If this fails, report the compile error and fix it before reporting the resume as done.

## General rules (apply to every section)

- **Format**: output must be valid YAML.
- **Rich text**: `summary` fields support a limited Markdown subset only — Bold, Italic, Links, Lists (ordered, unordered, nested). **Forbidden**: headings, blockquotes, images, horizontal rules, tables.
- **Dates**: align with the format in [assets/resume.example.yml](assets/resume.example.yml). For current roles or projects, **omit `endDate` or set it to null**. Do NOT use `"Present"` or `""`.
- **URLs**: omit if unknown, do NOT use `""`.
- **Forbidden sources**: never read or copy content from `*.example.yml` files. They are structural references only. This does **not** apply to reference resumes selected under step 4 — those are real prior output and are meant to be read, but only for style/structure (see [references/reference-resume-selection.md](references/reference-resume-selection.md)), never as a source of facts.

## Quick reference

| Need                                      | File                                                                                 |
| ----------------------------------------- | ------------------------------------------------------------------------------------ |
| JD analysis prompt                        | [references/job-analysis.md](references/job-analysis.md)                             |
| Company / business analysis prompt        | [references/company-business-analysis.md](references/company-business-analysis.md)   |
| Projects section prompt                   | [references/section-projects.md](references/section-projects.md)                     |
| Work Experience section prompt            | [references/section-work.md](references/section-work.md)                             |
| Skills section prompt                     | [references/section-skills.md](references/section-skills.md)                         |
| Personal Summary section prompt           | [references/section-personal-summary.md](references/section-personal-summary.md)     |
| Overall content principles                | [references/overview.md](references/overview.md)                                     |
| De-AI: English & romance languages        | [references/humanizer-en.md](references/humanizer-en.md)                             |
| De-AI: Chinese (simplified & traditional) | [references/humanizer-zh.md](references/humanizer-zh.md)                             |
| Resume quality review prompt              | [references/resume-review.md](references/resume-review.md)                           |
| Resume revision prompt                    | [references/resume-revision.md](references/resume-revision.md)                       |
| Reference resume selection (style)        | [references/reference-resume-selection.md](references/reference-resume-selection.md) |
| Review output structural template         | [assets/review.example.yml](assets/review.example.yml)                               |
| Resume YAML template                      | [assets/resume.example.yml](assets/resume.example.yml)                               |
| Per-section examples                      | [assets/section-\*.example.yml](assets/)                                             |
| Example JD                                | [assets/jd.example.txt](assets/jd.example.txt)                                       |
