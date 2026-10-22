#import "helpers.typ": linked-text
#import "spacing.typ": default-spacing, spacing-state

#let resume(
  author: "",
  author-position: left,
  personal-info-position: left,
  pronouns: "",
  location: "",
  email: "",
  email-text: "",
  github: "",
  github-text: "",
  linkedin: "",
  linkedin-text: "",
  phone: "",
  personal-site: "",
  personal-site-text: "",
  accent-color: "#000000",
  link-color: "#1155CC",
  font: "New Computer Modern",
  paper: "us-letter",
  author-font-size: 20pt,
  font-size: 10pt,
  section-title-scale: 1,
  section-content-inset: 2pt,
  margin: (0.5in),
  spacing: (:),
  lang: "en",
  body,
) = {
  let s = default-spacing + spacing

  set document(author: author, title: author)

  set text(
    font: font,
    size: font-size,
    lang: lang,
    ligatures: false,
  )

  set page(
    margin: margin,
    paper: paper,
  )

  show link: it => {
    if type(it.dest) == str and it.dest.starts-with("tel:") {
      it
    } else {
      underline(offset: s.link-offset, stroke: s.rule-stroke, it)
    }
  }

  show heading: set text(
    fill: rgb(accent-color),
  )

  show link: set text(
    fill: rgb(link-color),
  )

  show heading.where(level: 1): it => [
    #set align(author-position)
    #set text(
      weight: 600,
      size: author-font-size,
    )
    #pad(upper(it.body))
  ]

  spacing-state.update(s)

  [= #(author)]

  pad(
    top: 0em,
    bottom: s.after-header,
    align(personal-info-position)[
      #{
        let items = (
          linked-text(pronouns),
          linked-text(phone),
          linked-text(location),
          linked-text(email, text: email-text),
          linked-text(linkedin, link-prefix: "https://", text: linkedin-text),
          linked-text(github, link-prefix: "https://", text: github-text),
          linked-text(personal-site, link-prefix: "https://", text: personal-site-text),
        )
        items.filter(x => x != none).join(" | ")
      }
    ],
  )

  set par(justify: true, leading: s.leading, spacing: s.gap)
  set block(spacing: s.gap)
  // Tight lists otherwise attach with leading and ignore the entry header's below.
  show list: set block(above: s.row)

  pad(left: section-content-inset, {
    show heading.where(level: 2): it => block(above: s.before-section, below: 0pt, {
      pad(left: -section-content-inset, bottom: s.after-section-rule)[
        #set text(weight: 600, size: section-title-scale * font-size)
        #pad(top: 0pt, bottom: s.after-section-title, [#upper(it.body)])
        #line(length: 100% + section-content-inset, stroke: s.rule-stroke)
      ]
    })
    body
  })
}
