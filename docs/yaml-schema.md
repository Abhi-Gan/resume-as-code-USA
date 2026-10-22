# YAML Resume Schema Reference

This repo uses one YAML format for resume content: **New Schema v1.0**. There is no Legacy/YAMLResume format anymore — the old React/Puppeteer app and the LaTeX/YAMLResume compiler dependency have both been fully retired. Every resume renders via the Typst pipeline (see [`../README.md`](../README.md#typst-rendering-pipeline)).

---

## New Schema (v1.0)

Discriminated section types, stable IDs, visibility flags, layout hints, and flexible content structures.

```yaml
schema:
  version: '1.0'
  generator: resume-as-code

document:
  title: 'My Resume'
  language: en # en | zh-hans | zh-hant-hk | zh-hant-tw | es | fr | no

basics:
  name: Zhang Wei
  headline: 'Senior Data Engineer · 7 YOE'
  phone: '+86 138 8888 8888'
  email: zhangwei@outlook.com
  url: zhangwei.dev
  summary:
    - 'Bullet point one describing core competency.'
    - 'Bullet point two with specific achievements.'
  profiles:
    - network: GitHub
      url: https://github.com/zhangwei
      username: github.com/zhangwei

sections:
  - id: work
    type: work
    title: 'Work Experience'
    items:
      - id: job-1
        name: Acme Corp
        position: Senior Engineer
        startDate: '2022-01'
        endDate: '2024-06'
        summary:
          - 'Led migration of data platform to lakehouse architecture.'
          - 'Reduced pipeline latency by 60% through stream processing.'
        keywords: [Spark, Kafka, AWS, Terraform]

  - id: education
    type: education
    title: 'Education'
    items:
      - institution: MIT
        degree: Master
        area: Computer Science
        startDate: '2018-09'
        endDate: '2020-06'

  - id: projects
    type: projects
    title: 'Projects'
    items:
      - id: proj-1
        name: Data Platform v2
        description: 'Enterprise-scale lakehouse platform'
        startDate: '2023-03'
        endDate: '2024-01'
        summary:
          - 'Designed and implemented end-to-end lakehouse on AWS.'
        keywords: [Databricks, Delta Lake, Airflow]

  - id: skills
    type: skills
    title: 'Skills'
    items:
      - name: Languages
        keywords: [Python, SQL, TypeScript, Go]
      - name: Data
        keywords: [Spark, Kafka, Airflow, dbt]

  - id: certificates
    type: certificates
    title: 'Certificates'
    items:
      - name: AWS Certified Data Analytics
        issuer: Amazon Web Services
        date: '2023-05'

  - id: langAndInterests
    type: langAndInterests
    title: 'Languages & Interests'
    languages:
      - language: English
        fluency: Professional Working
      - language: Mandarin Chinese
        fluency: Native
    interests:
      - name: Open Source
        keywords: [data tooling, contributor]

# Optional: explicit section display order
order:
  - work
  - education
  - projects
  - skills
  - certificates
  - langAndInterests

layout:
  template: tech-compact # any subdirectory of templates/ with an adapter.typ - currently tech-compact | zhiweio
```

**`layout.template`**: records which template this resume's content was drafted for — the discovered set under `templates/` (currently `tech-compact`, `zhiweio`; see [`skills/resume-generation/SKILL.md`](../skills/resume-generation/SKILL.md) for how that discovery works). `jake` predates this pipeline and currently has no renderer at all — it is not a selectable option. Optional, defaults to `tech-compact`.

This field matters most _during generation_ — it's what tells the resume-generation skill which structural rules to follow (whether to draft a Skills section, a personal summary, etc. — see `SKILL.md`). It is **not** currently read at render time: the per-resume Typst stub (`data/resumes/{Name}.typ`) hardcodes which template adapter it imports, independent of this field. If you ever hand-edit `layout.template` on an existing resume, the matching stub's `#import` line needs updating to match — see `SKILL.md` step 10 for the rule on how that's done safely (without clobbering any hand-tuned `theme:` overrides in the stub).

**Paper size, font size, spacing, and margins are not YAML fields.** They live entirely in the per-resume Typst stub's `theme:` argument (`render(data, theme: (font-size: 9.6pt, margin: (0.3in), ...))`), since they're presentation choices, not resume content. See [`templates/tech-compact/adapter.typ`](../templates/tech-compact/adapter.typ) for the full set of overridable keys and their defaults.
