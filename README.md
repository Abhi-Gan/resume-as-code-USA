# Resume as Code

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Node.js](https://img.shields.io/badge/Node.js-≥18-green.svg)](https://nodejs.org) [![pnpm](https://img.shields.io/badge/pnpm-≥9-orange.svg)](https://pnpm.io)

</div>

<div align="center">

**Stop copy-pasting resumes.** Maintain a single YAML timeline of your career, and let AI agents generate perfectly targeted resumes for every job application — in minutes, not hours.

</div>

---

## Table of Contents

- [Resume as Code](#resume-as-code)
  - [Table of Contents](#table-of-contents)
  - [Highlights](#highlights)
  - [Quick Start](#quick-start)
    - [Prerequisites](#prerequisites)
    - [1. Install skills for your agent](#1-install-skills-for-your-agent)
    - [2. Build your timeline](#2-build-your-timeline)
    - [3. Configure your profile](#3-configure-your-profile)
    - [4. Generate a tailored resume](#4-generate-a-tailored-resume)
    - [5. Preview and export PDF](#5-preview-and-export-pdf)
  - [Typst Rendering Pipeline](#typst-rendering-pipeline)
  - [AI Agent Skills](#ai-agent-skills)
    - [Agent compatibility](#agent-compatibility)
  - [Project Structure](#project-structure)
  - [YAML Resume Schema](#yaml-resume-schema)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

---

## Highlights

- **Single source of truth** — all career data lives in modular YAML files (profiles, timeline, drafts)
- **3 AI agent skills** — resume generation, timeline polishing, and interview preparation, powered by LLMs
- **10-step generation pipeline** — company research → JD analysis → section generation → de-AI humanization → quality review → revision
- **Typst rendering pipeline** — YAML content stays the source of truth; a thin per-template Typst adapter handles layout, with per-resume theme overrides (font size, spacing, margin) for fitting content to one page
- **Single YAML format** — New Schema v1.0 only. There is no Legacy/YAMLResume/LaTeX path anymore; both the old React/Puppeteer app and the LaTeX compiler dependency have been fully retired
- **Any language, written directly** — Typst falls back to a glyph-capable font automatically (no CJK-aware font config needed), section `title` fields and dates are free text with no reformatting, so non-English resumes work by typing the translated content directly. What's gone is the old automatic layer (`document.language` no longer auto-picks a font, translates titles, or formats dates for you) — not the capability itself.
- **11+ agent support** — works with Claude Code, Codex, GitHub Copilot, Cursor, Windsurf, Cline, Trae, and more

---

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org) ≥ 18 and [pnpm](https://pnpm.io) ≥ 9
- An AI coding agent (e.g., [Claude Code](https://claude.ai/claude-code), GitHub Copilot, Cursor, etc.)

### 1. Install skills for your agent

```bash
git clone https://github.com/zhiweio/resume-as-code.git
cd resume-as-code
pnpm install
pnpm skills:install <agent>   # e.g. claude, copilot, cursor, windsurf, cline
```

See the full [agent compatibility table](#agent-compatibility) below.

### 2. Build your timeline

Open your AI agent and paste raw descriptions of your past jobs or projects. The **Timeline Polishing Agent** will structure them using STAR (work) or 3W (project) methodology and save to `data/timeline/`.

### 3. Configure your profile

Fill in your static data in `data/profiles/`:

| File                         | Content                                                                                                                                | Required?                                               |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `basics.yml`                 | Name, phone, email, URL, summary, social profiles                                                                                      | Yes                                                     |
| `education.yml`              | Institutions, degrees, dates                                                                                                           | Yes                                                     |
| `certificates.yml`           | Certifications                                                                                                                         | Yes                                                     |
| `writing-style.md`           | Personal phrasing preferences (bolding density, verb variety, ATS habits) — read by the Resume Generation Agent while drafting bullets | Optional — skipped silently if absent                   |
| `generation-preferences.yml` | Your personal defaults for the Resume Generation Agent's startup prompt (research depth, template, review/revision settings)           | Optional — falls back to the skill's hardcoded defaults |

Example templates are provided for every file above — copy `basics.example.yml` → `basics.yml` (same pattern for `writing-style.example.md`, `generation-preferences.example.yml`, etc.) and edit.

### 4. Generate a tailored resume

Paste a Job Description into your agent. The **Resume Generation Agent** will ask a quick startup prompt (research depth, template, review/revision settings — defaults can be preset in `generation-preferences.yml`), then:

1. Research the company's business context (depth configurable: full / light / skip)
2. Deep-analyze the JD to infer actual role requirements
3. Match relevant experiences from your timeline
4. Generate tailored sections (projects → work → skills → summary)
5. Assemble, de-AI humanize, review, and optionally revise

Output: `data/resumes/{Name}_{JobTitle}_{Company}.yml`, plus a matching `data/resumes/{Name}_{JobTitle}_{Company}.typ` stub (see below).

### 5. Preview and export PDF

Every resume renders via Typst. The `.typ` file next to your resume's YAML is a complete, self-contained Typst document — open it directly in any Typst-aware editor (e.g. [Typstify](https://marketplace.visualstudio.com/items?itemName=typstify.typstify) or [tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) in VS Code) for a live PDF preview on save, or compile it once from the command line:

```bash
typst compile --root . "data/resumes/Your_Resume.typ" Your_Resume.pdf
```

If a resume runs long, nudge font size, spacing, or margin in that `.typ` file's `theme: (...)` block rather than editing the YAML or the template — see [`templates/tech-compact/adapter.typ`](templates/tech-compact/adapter.typ) for the overridable keys.

---

## Typst Rendering Pipeline

Each resume has two files: the YAML (content — the only thing you or your agent should edit) and a matching `.typ` stub (rendering wiring, mechanically generated, not hand-authored content):

```
data/resumes/Your_Resume.yml    # content — bullets, dates, keywords
data/resumes/Your_Resume.typ    # 3-line stub: imports the template, loads the YAML, renders it
```

A per-template Typst **adapter** (`templates/<name>/adapter.typ`) sits between the two — it reads the YAML and calls into a **vendored** Typst template (`templates/<name>/vendor/`) for actual layout/typography. The adapter is built once per template and almost never touched again; per-resume generation only ever changes the YAML.

The `.typ` stub is also where **per-resume presentation overrides** live — font size, line spacing, margin, paper size — passed as a `theme:` argument, separate from both content and template code:

```typst
#import "../../templates/tech-compact/adapter.typ": render
#let data = yaml("Your_Resume.yml")
#render(data, theme: (font-size: 9.6pt, margin: (0.3in)))
```

Most resumes never need a `theme:` override; add one when a specific resume runs long and needs tightening to fit one page. See [`templates/tech-compact/adapter.typ`](templates/tech-compact/adapter.typ) for the full list of overridable keys and their defaults.

`template = jake` predates this pipeline and currently has **no renderer at all** — its only two renderers (the old React/Puppeteer app, and the LaTeX/YAMLResume path) have both been removed. It's not a selectable option anymore (see `skills/resume-generation/SKILL.md`). Onboarding it as a real option again is a matter of repeating the same vendor + adapter pattern under `templates/jake/`.

---

## AI Agent Skills

Three portable [Agent Skills](https://agentskills.io) under [`skills/`](skills/), each self-contained as `SKILL.md` + `references/` + `assets/`:

| Skill                                                            | Trigger                                 | Output                                         |
| ---------------------------------------------------------------- | --------------------------------------- | ---------------------------------------------- |
| [`resume-generation`](skills/resume-generation/SKILL.md)         | User provides a Job Description         | Tailored YAML resume in `data/resumes/`        |
| [`timeline-polishing`](skills/timeline-polishing/SKILL.md)       | User provides raw work or project notes | Structured YAML in `data/timeline/`            |
| [`interview-preparation`](skills/interview-preparation/SKILL.md) | Resume + JD Analysis + Company Analysis | Markdown interview guide in `data/interviews/` |

### Agent compatibility

```bash
pnpm skills:install <agent>          # one agent
pnpm skills:install all              # all supported
pnpm skills:uninstall <agent>|all    # clean removal
```

| Agent                                                                         | How                                                                              |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Claude Code**                                                               | `pnpm skills:install claude` or `/plugin marketplace add zhiweio/resume-as-code` |
| **GitHub Copilot**                                                            | Zero-config (committed `.github/copilot-instructions.md`)                        |
| **Codex** / **OpenCode** / **Aider** / **Qoder** / **Continue** / **RooCode** | Zero-config (reads `AGENTS.md`)                                                  |
| **Cursor**                                                                    | Zero-config (via `AGENTS.md`) or `pnpm skills:install cursor`                    |
| **Trae**                                                                      | Zero-config (committed `.trae/rules/project_rules.md`)                           |
| **Windsurf**                                                                  | `pnpm skills:install windsurf`                                                   |
| **Cline** / **RooCode**                                                       | `pnpm skills:install cline`                                                      |

See [`skills/README.md`](skills/README.md) for detailed agent instructions and how to add new agents.

---

## Project Structure

```text
.
├── AGENTS.md                 # Universal entry point for all coding agents
├── skills/                   # Three portable Agent Skills
│   ├── resume-generation/    #   JD → tailored YAML resume (10-step pipeline)
│   ├── timeline-polishing/   #   Raw notes → STAR/3W YAML timeline
│   └── interview-preparation/#   Resume + JD → interview guide
├── scripts/
│   └── install-skills.mjs    # One-command multi-agent installer
├── templates/                # Typst rendering templates
│   └── tech-compact/         #   vendor/ (upstream template) + adapter.typ
├── data/                     # All user-owned content
│   ├── profiles/             #   Static candidate data (basics, education, certificates)
│   ├── timeline/             #   Master timeline library (polished YAML)
│   ├── drafts/               #   Raw notes for polishing
│   ├── resumes/              #   Generated tailored resumes
│   ├── interviews/           #   Generated interview guides
│   └── .cache/               #   Per-run intermediate artifacts (gitignored)
└── docs/
    └── yaml-schema.md        # YAML format reference (New Schema v1.0)
```

---

## YAML Resume Schema

Resumes are New Schema v1.0 — discriminated section types, stable IDs, layout hints, theme overrides. There is no Legacy/YAMLResume format anymore.

For full schema documentation with examples, see **[docs/yaml-schema.md](docs/yaml-schema.md)**.

---

## License

[MIT](LICENSE)

---

## Acknowledgments

- [blader/humanizer](https://github.com/blader/humanizer) — English AI writing pattern detection and removal
- [op7418/humanizer-zh](https://github.com/op7418/humanizer-zh) — Chinese AI writing pattern detection and removal
- [itMrBoy/resumePolice](https://github.com/itMrBoy/resumePolice) — Comprehensive resume review framework
