// "zhiweio" template: a faithful Typst port of the original resume-builder-app
// React/Puppeteer renderer's techCompact template (zhiweio/resume-as-code,
// the upstream project this repo forked from), recovered from git history
// before that app was removed. This is a distinct, separate look from the
// "tech-compact" template (which has blue links and an uppercase name) -
// zhiweio is all-black throughout, flat uniform font size, name in natural
// case, and no link styling, exactly matching the original.
//
// Self-contained (no vendor/ dir): there's no upstream Typst package to vendor
// here, this is an original reimplementation of zhiweio's own React design.
// Every numeric default below is ported directly from the recovered source
// (git show HEAD~N:resume-builder-app/...), px -> pt via *0.75 (96 DPI, the
// value the old renderer assumed - confirmed via its own letter-size pixel
// dimensions).

#import "@preview/cmarker:0.1.10"

#let md(s) = cmarker.render(s)

#let find-profile(profiles, network) = {
  let matches = profiles.filter(p => p.network == network)
  if matches.len() > 0 { matches.first() } else { none }
}

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

// TechCompactEntryHead.tsx's composeTitleLine, ported 1:1.
#let compose-title(item, kind) = {
  if kind == "work" {
    let loc = if item.at("location", default: "") != "" { ", " + item.location } else { "" }
    "**" + item.name + "**" + loc + " (_" + item.position + "_)"
  } else if kind == "projects" {
    if item.at("description", default: "") != "" {
      "**" + item.name + "**: " + item.description
    } else {
      "**" + item.name + "**"
    }
  } else {
    "**" + item.institution + "**"
  }
}

#let default-theme = (
  font: "Arial", // old app: Calibri, falls back to Arial/sans-serif - same reasoning as tech-compact
  name-size: 14pt, // 15px
  body-size: 9pt, // 11px - flat/uniform across every role in the original (name is the one exception)
  margin: (0.4167in), // 40px page margin @ 96dpi
  paper: "us-letter",
  spacing: (
    after-header: 3pt, // headlineMarginTop: 4px (name -> contact line)
    before-section: 7pt, // spacing.sectionGap: 5px, loosened - see note below
    after-section-title: 5pt, // secHeadRuleMarginTop: 3px (title -> rule line)
    after-section-rule: 6pt, // secHeadMarginBottom: 5px (rule line -> first entry), loosened
    after-entry-head: 3pt, // entryHeadMarginBottom: 2px, loosened
    before-edu-subrow: 5pt, // entrySubMarginTop: 1px, loosened
    between-bullets: 5pt, // bulletMarginBottom: 1px, loosened
    bullet-gap: 5pt, // bulletGap: 5px (marker -> text)
    between-entries: 7pt, // not present in the recovered source as a named constant; approximated to match the overall density
    leading: 0.5em, // space between wrapped lines within a bullet/paragraph - Typst-specific, no direct source equivalent
  ),
)
// The px values above were the original's *extra margin* on top of a fairly
// generous 1.45x line-height (CSS) - Typst's default leading is tighter, so
// a literal px->pt port of just the margins alone reads as cramped. Bumped
// the margin-equivalents up and set `leading` explicitly below (in render())
// to compensate, rather than trying to find one precise conversion factor.

#let section-head(title, s) = {
  // stack(), not two sibling blocks - Typst inserts its own implicit spacing
  // between block-level siblings, which was silently dwarfing the explicit
  // after-section-title value. stack(spacing:) is exact, nothing implicit added.
  block(above: s.before-section, below: 0pt,
    stack(
      spacing: s.after-section-title,
      text(weight: 700)[#upper(title)],
      line(length: 100%, stroke: 0.75pt + black),
    )
  )
  v(s.after-section-rule, weak: true)
}

#let entry-head(item, kind, s) = {
  grid(
    columns: (1fr, auto),
    column-gutter: 8pt,
    align: (left, right + horizon),
    md(compose-title(item, kind)),
    strong(fmt-date(item.at("startDate", default: none), item.at("endDate", default: none))),
  )
  if kind == "education" {
    v(s.before-edu-subrow, weak: true)
    grid(
      columns: (1fr, auto),
      column-gutter: 8pt,
      align: (left, right + horizon),
      emph[#item.degree #sym.dot.c #item.area],
      if "gpa" in item { strong[GPA: #item.gpa] } else { [] },
    )
  }
}

#let keyword-bullet(item) = {
  if "keywords" in item and item.keywords.len() > 0 {
    emph(item.keywords.join(", "))
  } else {
    none
  }
}

#let entry-bullets(item, s) = {
  let lines = ()
  let kw = keyword-bullet(item)
  if kw != none { lines.push(kw) }
  for line in item.at("summary", default: ()) {
    lines.push(md(line))
  }
  if lines.len() > 0 {
    set list(marker: [•], indent: 0pt, body-indent: s.bullet-gap, spacing: s.between-bullets)
    for line in lines {
      [- #line]
    }
  }
}

#let render-entry(item, kind, s) = {
  block(below: s.between-entries, {
    entry-head(item, kind, s)
    v(s.after-entry-head, weak: true)
    entry-bullets(item, s)
  })
}

#let default-section-titles = (
  education: "Education",
  work: "Experience",
  research: "Research",
  projects: "Projects",
)

#let render-section(section, s) = {
  section-head(section.at("title", default: default-section-titles.at(section.id, default: section.id)), s)
  for item in section.items {
    render-entry(item, section.type, s)
  }
}

#let render(data, theme: (:)) = {
  let t = default-theme + theme
  let s = default-theme.spacing + theme.at("spacing", default: (:))
  let linkedin = find-profile(data.basics.at("profiles", default: ()), "LinkedIn")
  let github = find-profile(data.basics.at("profiles", default: ()), "GitHub")

  set document(author: data.basics.name, title: data.basics.name)
  set page(margin: t.margin, paper: t.paper)
  set text(font: t.font, size: t.body-size, fill: black)
  set par(justify: true, leading: s.leading)

  align(center)[#text(size: t.name-size, weight: 700)[#data.basics.name]]
  v(t.spacing.after-header, weak: true)

  let contact-parts = ()
  let phone = data.basics.at("phone", default: "")
  if phone != "" { contact-parts.push(phone) }
  let email = data.basics.at("email", default: "")
  if email != "" { contact-parts.push(email) }
  if linkedin != none { contact-parts.push(link("https://" + strip-scheme(linkedin.url))[#strip-scheme(linkedin.url)]) }
  if github != none { contact-parts.push(link("https://" + strip-scheme(github.url))[#strip-scheme(github.url)]) }
  let site = data.basics.at("url", default: "")
  if site != "" { contact-parts.push(link("https://" + strip-scheme(site))[#strip-scheme(site)]) }

  align(center)[#contact-parts.join([ | ])]

  for section-id in data.order {
    let matches = data.sections.filter(sec => sec.id == section-id)
    if matches.len() > 0 {
      render-section(matches.first(), s)
    }
  }
}
