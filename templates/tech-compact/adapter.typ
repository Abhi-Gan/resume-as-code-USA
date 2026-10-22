// Tech-Compact adapter: reads a per-resume YAML (New Schema v1.0) and drives
// the vendored exp-resume components. Built once during onboarding; per-resume
// generation never touches this file - only the YAML it reads does.
//
// Known gap: the reference resume includes the candidate's own city/state in
// the contact line (e.g. "Palo Alto, CA"). data/profiles/basics.yml has no
// `location` field today, so that's omitted here rather than fabricated.

#import "vendor/lib.typ": resume, generic-one-by-two, generic-two-by-two
#import "@preview/cmarker:0.1.10"

// Inline markdown (**bold**, [text](url)) -> Typst content, for the only
// fields confirmed to carry it: entry `summary` bullets and project `name`.
#let md(s) = cmarker.render(s)

#let default-section-titles = (
  education: "Education",
  work: "Experience",
  research: "Research",
  projects: "Projects",
  certificates: "Certificates",
  extracurriculars: "Activities",
)

#let find-profile(profiles, network) = {
  let matches = profiles.filter(p => p.network == network)
  if matches.len() > 0 { matches.first() } else { none }
}

// vendor's linked-text() always prepends "https://" itself, so a value that
// already has a scheme (every url field in our YAML does) would double up
// into "https://https://...". Strip it before handing values off to resume().
#let strip-scheme(url) = {
  for prefix in ("https://", "http://") {
    if url.starts-with(prefix) {
      return url.slice(prefix.len())
    }
  }
  url
}

#let fmt-date(start, end) = {
  let end-display = if end == none or end == "" or end == "Present" { "Present" } else { end }
  if start == none or start == "" { end-display } else { start + " " + sym.dash.en + " " + end-display }
}

#let entry-bullets(summary) = {
  for line in summary {
    [- #md(line)]
  }
}

#let keywords-bullet(item) = {
  if "keywords" in item and item.keywords.len() > 0 {
    [- #emph(item.keywords.join(", "))]
  }
}

#let render-work-entry(item) = {
  generic-one-by-two(
    left: [*#item.name*#if item.at("location", default: "") != "" [, #item.location] #emph[(#item.position)]],
    right: fmt-date(item.at("startDate", default: none), item.at("endDate", default: none)),
  )
  keywords-bullet(item)
  entry-bullets(item.at("summary", default: ()))
}

#let render-edu-entry(item) = {
  generic-two-by-two(
    top-left: [*#item.institution*],
    top-right: strong(fmt-date(item.at("startDate", default: none), item.at("endDate", default: none))),
    bottom-left: emph[#item.degree in #item.area],
    bottom-right: if "gpa" in item { strong[GPA: #item.gpa] } else { [] },
  )
  entry-bullets(item.at("summary", default: ()))
}

#let render-project-entry(item) = {
  generic-one-by-two(
    left: [#md("**" + item.name + "**")#if item.at("description", default: "") != "" [ #sym.dash.en #item.description]],
    right: fmt-date(item.at("startDate", default: none), item.at("endDate", default: none)),
  )
  keywords-bullet(item)
  entry-bullets(item.at("summary", default: ()))
}

#let render-section(section) = {
  heading(level: 2)[#section.at("title", default: default-section-titles.at(section.id, default: section.id))]
  for item in section.items {
    if section.type == "education" {
      render-edu-entry(item)
    } else if section.type == "work" {
      render-work-entry(item)
    } else if section.type == "projects" {
      render-project-entry(item)
    }
  }
}

#let default-theme = (
  font: "Arial",
  author-font-size: 14pt,
  font-size: 10pt,
  section-title-scale: 1,
  spacing: (:),
  margin: (0.5in),
  paper: "us-letter",
)

#let render(data, theme: (:)) = {
  let t = default-theme + theme
  let linkedin = find-profile(data.basics.at("profiles", default: ()), "LinkedIn")
  let github = find-profile(data.basics.at("profiles", default: ()), "GitHub")

  show: resume.with(
    author: data.basics.name,
    phone: data.basics.at("phone", default: ""),
    email: data.basics.at("email", default: ""),
    linkedin: if linkedin != none { strip-scheme(linkedin.url) } else { "" },
    linkedin-text: if linkedin != none { strip-scheme(linkedin.url) } else { "" },
    github: if github != none { strip-scheme(github.url) } else { "" },
    github-text: if github != none { strip-scheme(github.url) } else { "" },
    personal-site: strip-scheme(data.basics.at("url", default: "")),
    font: t.font,
    author-font-size: t.author-font-size,
    font-size: t.font-size,
    section-title-scale: t.section-title-scale,
    spacing: t.spacing,
    margin: t.margin,
    paper: t.paper,
    author-position: center,
    personal-info-position: center,
    accent-color: "#000000",
  )

  for section-id in data.order {
    let matches = data.sections.filter(s => s.id == section-id)
    if matches.len() > 0 {
      render-section(matches.first())
    }
  }
}
