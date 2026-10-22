Vendored from [exp-resume-template](https://github.com/tahzeer/exp-resume-template) (v0.1.2, Unlicense).

This is the upstream source as of 2026-10-20, used as the starting point for the Tech-Compact
Typst template. Almost all customization (font, entry-header layout, spacing) is done from
`../adapter.typ` via `resume.with(...)` config and by composing the exported helpers directly
(bypassing `work()`/`edu()` to get a one-line entry header) - no vendor edits needed for that.

Direct edits made here (diff against upstream before updating this vendor copy):

- `resume.typ` heading show-rules: section titles (level-2) are `upper()` + weight 600 instead of
  `smallcaps()` + weight 400, and the author name (level-1) is also `upper()`-wrapped (it was
  reading as visually smaller than the bold all-caps section headers at the same font size).
- `resume.typ` contact line: added a `link-color` param, decoupled from `accent-color`, so links
  render blue without recoloring headings/name. Phone and email are no longer wrapped in
  `tel:`/`mailto:` links at all (plain text) - only LinkedIn/GitHub/personal-site stay clickable.
- `resume.typ` level-2 heading block: wrapped in `block(above: s.before-section)` so the gap above
  each section title is an explicit, tunable value instead of Typst's implicit default heading
  spacing.
- `spacing.typ`: added `before-section` (see above); changed `link-offset` from a fixed `4pt` to
  `auto`, which uses the font's natural underline position instead of a manually pushed-down one.
