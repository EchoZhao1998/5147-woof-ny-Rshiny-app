# Woof! New York — Design Decisions Log

*Source material for the DVP Part 2 written report (Sections 2 *Design Process* and 3.2 *Interactive Narrative Visualisation Implementation*). Each entry below captures what was built, why, and which unit-material reference applies, so the report can paraphrase rather than start from scratch.*

---

## How to read this file

Each design entry follows the same shape:

- **TL;DR** — one line; what was decided. Skim these to navigate.
- **What was built / Choice** — the concrete decision.
- **Why** — the reasoning, with unit-material references where applicable.
- **Trade-off / Implementation note / Bug fixed** — secondary details (only when relevant).

To find a decision: jump to the Build Status table → click the tab section → scan TL;DRs. The full prose is for when you're paragraphing this into the report.

---

## Build status

| Tab | Status | Session built | Section in this file |
|---|---|---|---|
| Tab 1 — Introduction | Built | DVP1→2 transition (pre 2026-05-18) | [Tab 1](#tab-1-introduction) |
| Tab 2 — Trends | Built | 2026-05-18 | [Tab 2](#tab-2-trends) |
| Tab 3 — Infrastructure | Built | 2026-05-18 | [Tab 3](#tab-3-infrastructure) |
| Tab 4 — Safety | Pending | — | [Tab 4](#tab-4-safety) |
| Tab 5 — About | Pending | — | [Tab 5](#tab-5-about) |

Open decisions still on the table → [Open items](#open-items-for-next-session).

---

## Session log

Reverse-chronological — most recent first.

### 2026-05-18 — Tab 3 (Infrastructure) built

**Scope:** full Tab 3 build — data prep (centroids, palette closures, pre-built hover labels), UI (radio toggle + leaflet), server (renderLeaflet base + leafletProxy observer), house-style narrative reflection. `viridisLite` added to library set. Borough-code translation added to dog-run loading.

**Files touched:** `app.R` (sections 1, 2c, 3f new, UI Tab 3, server Tab 3), `HANDOVER.md`, `notes_for_report.md`.

**Decisions made this session:**

- **Layout mirrors Tab 2** — `sidebarLayout(3/9)` with radio toggle on the left, leaflet on the right. Defers the literal DVP2_UI right-narrative-panel for cross-tab consistency. See [Layout entry](#layout--sidebarlayout-mirror-of-tab-2).
- **Two-palette toggle (plasma for density, viridis for gap)** — distinct hue families instead of "darker vs lighter green" so the user can see which view is active without consulting the legend. See [Palette entry](#two-palette-toggle--plasma-for-density-viridis-for-gap).
- **Sqrt transform on `dog_density` only** — right-skew correction; legend back-transforms with `labelFormat(transform = function(x) x^2)`. `gap_index` left untransformed because it's already in [0, 1]. See [Sqrt entry](#sqrt-transform-on-dog_density-only).
- **Time-horizon mismatch (density 2022 vs bite_rate cumulative) acknowledged** — kept as-is rather than recomputed, called out in the Tab 3 Important-context callout and in this log. See [Time-horizon entry](#time-horizon-mismatch--density-2022-vs-bite_rate-cumulative).
- **`renderLeaflet` + `leafletProxy` pattern** — base map (tiles + view + 91 circle markers) drawn once; observer mutates only the choropleth + legend on toggle. See [Proxy entry](#renderleaflet--leafletproxy-pattern).
- **CartoDB Positron basemap** — low-contrast tiles so the choropleth carries the colour story. See [Basemap entry](#cartodb-positron-basemap).
- **Circle markers, not paw icons** — neutral dark dot + white halo. Borough is already encoded by the ZCTA underneath; adding marker colour would be redundant encoding. See [Marker entry](#circle-markers-over-paw-icons--decision-resolved).
- **Hover label / click popup split** — polygons use `label` (hover, lightweight context tag), markers use `popup` (click-to-pin for named entities). See [Tooltip entry](#tooltip-design--hover-label-on-polygons-click-popup-on-markers).
- **Highlight-on-hover changes border only, not fill** — preserves the colour encoding (Munzner ch.11). See [Highlight entry](#highlight-on-hover--border-only-not-fill).
- **Branch-free observer body** — four metric-specific values bound at the top, then a single `addPolygons + addLegend` call. Less repetition than two duplicated 15-line branches. See [Observer entry](#observer-structure--branch-free-rendering).
- **`case_match()` over `recode()`** — modern dplyr (≥ 1.1.0) idiom; `recode` is in "questioning" status. Same call style across the codebase. See [case_match entry](#dplyrcase_match-over-dplyrrecode).

**Bug fixed during this session:** initial `dog_run_centroids` build used `mutate(lon = sf::st_coordinates(geometry)[, 1], ...)` — copied from the borough-centroids block. Failed with `object 'geometry' not found` at app start because `dog_runs`'s active geometry column is named `the_geom` (preserved from the CSV's WKT column during `st_as_sf(wkt = "the_geom")`), not `geometry`. `master_filtered`'s column *is* `geometry` only because the DEP wrangling explicitly used `summarise(geometry = sf::st_union(geometry))`. Fix: call `sf::st_coordinates()` on the sf object itself (not on a named column) and assign `$lon` / `$lat` via base-R `<-` — name-agnostic and unaffected by which sf object you use.

### 2026-05-18 — Tab 2 (Trends) built

**Scope:** typography CSS fix, full Tab 2 build, design log update, audience-voice pass, Echo's narrative restructure.

**Files touched:** `app.R` (sections 2b, 3e, 4, UI Tab 2, server Tab 2), `HANDOVER.md`, `notes_for_report.md`.

**Decisions made this session:**

- **Typography cascade fixed** — Futura first with Mac→Windows fallback chain; body weight 400; broken `font_weight: 100` typo removed; serif hero pairing considered and rejected. See [Typography entry](#typography--futura-body-robust-fallback-cascade-weight-400).
- **`plot_ly()` over `ggplotly()`** for the Trends chart — `annotate("rect", ...)` doesn't translate reliably. See [Native plot_ly entry](#native-plot_ly-over-ggplotly).
- **Annotation layer baked into the chart** — yellow 2019.5–2020.5 band + "COVID-19 drop" and "Recovery peak" labels at `yref = "paper"`. See [Annotation entry](#annotation-layer--covid-band--20202022-labels).
- **Rich tooltip chosen over simple** — pre-built per-row hover string with YoY % and a 2020/2022 context flag. Simple 3-line variant was prototyped in parallel and rejected. See [Tooltip entry](#tooltip-design--rich-tooltip-chosen-after-side-by-side-comparison).
- **YoY pre-computed at startup**, not in the reactive — *split-phase* principle. See [YoY entry](#yoy-computed-once-at-startup-not-in-the-reactive).
- **Interpretive narrative below the chart** — Echo restructured my four-paragraph draft into `<h3>` lead + two narrative paragraphs + three `<h4>` callouts (*Key takeaway* / *Important context* / *Continue exploring* with bulleted hand-off to Tabs 3 & 4). This shape is now the house style for tab reflections. See [Narrative entry](#interpretive-narrative-below-the-chart--house-style-for-tab-reflections).
- **Audience voice locked in** — NYC residents who own or are considering a dog; plain second-person, no academic hedges. See [Audience-voice entry](#audience-voice--plain-friendly-not-academic).

### Earlier sessions — Tab 1 + scaffolding

**Scope:** project skeleton, library set, data loading + bite-rate recompute, palette switch, KPI computation, Tab 1 full build, inline CSS.

**Decisions made:** single-file `app.R`, bite-rate recompute, Okabe-Ito palette, namespaced dplyr verbs, KPI helper, inline CSS, hero-question framing on Tab 1, static reference map.

---

## Cross-cutting decisions

*Apply everywhere; don't repeat per-tab.*

### Single-file `app.R` (not `ui.R` / `server.R` / `global.R`)

**TL;DR:** One file is easier for the marker to read end-to-end and avoids cross-file path bookkeeping.

**Choice:** Keep all code in one file.

**Why:** For an app of this size (~500 lines projected) splitting adds friction without adding value. One file is easier for the marker to read end-to-end, and it eliminates cross-file path bookkeeping. The classic three-file split is helpful when multiple authors are working in parallel or the app exceeds ~1000 lines.

**Trade-off acknowledged:** Long files can become harder to navigate. Mitigated by clear section headers (`# 1. LIBRARIES`, `# 2. DATA`, etc.) and a table-of-contents-style top comment.

### Bite-rate recompute inside `app.R`, not in the rds

**TL;DR:** Recompute the cumulative bite rate at app start so the formula sits next to the UI label that uses it.

**Choice:** `bite_rate = total_bites / total_dogs * 1000` recomputed at app start, where `total_dogs` is the cumulative 2016–2023 licensed-dog count.

**Why:** The DEP wrangling script overwrote `master_filtered.rds` with a 2022-only denominator during Phase 3 exploration. Recomputing in `app.R` keeps the formula sitting two lines away from every UI label that uses the metric, so the definition is self-evident. It also preserves the DEP submission as-is.

**Reference:** Munzner's *what-why-how* — the *what* (cumulative denominator) must match the *what* communicated in the UI label.

### Borough colour palette — Okabe & Ito (2008)

**TL;DR:** Switched to a deuteranopia-safe palette so Brooklyn and Bronx remain distinguishable to colourblind readers.

**Choice:** Switched from the original DEP palette to Okabe-Ito's qualitative colourblind-safe set.

| Borough | Old hex (DEP) | New hex (Okabe-Ito) | Hue |
|---|---|---|---|
| Manhattan | `#3182bd` | `#0072B2` | blue |
| Brooklyn | `#c51b8a` | `#CC79A7` | reddish purple |
| Queens | `#feb24c` | `#E69F00` | orange |
| Bronx | `#31a354` | `#009E73` | bluish green |
| Staten Island | `#e6550d` | `#D55E00` | vermillion |

**Why:** The DEP palette paired Brooklyn pink-magenta with Bronx green — a red-green pair that is the textbook problem for deuteranopia (the most common form of colour-vision deficiency, affecting ~6% of men of Northern European descent). Okabe-Ito was designed specifically to remain distinguishable under deuteranopia, protanopia, and tritanopia.

**References:**

- Okabe, M. & Ito, K. (2008). *Color Universal Design (CUD): How to make figures and presentations that are friendly to colorblind people.* https://jfly.uni-koeln.de/color/
- Wong, B. (2011). Color blindness. *Nature Methods*, 8, 441.

**How to apply across tabs:** The same five hex codes drive every plot, every map, and the KPI-card accents. Same borough → same colour everywhere (Gestalt: similarity).

### dplyr verbs are namespaced

**TL;DR:** Use `dplyr::filter` etc. because `plotly` also exports `filter()` and shadows the global namespace.

**Choice:** `dplyr::select`, `dplyr::filter`, `dplyr::mutate`, `dplyr::if_else` in the data-wrangling section.

**Why:** `plotly` exports its own `filter()` for plotly transforms. We load `plotly` after `dplyr`, which means `dplyr::filter` would be shadowed by `plotly::filter` in the global namespace. Namespacing the wrangling calls eliminates the ambiguity and is self-documenting — a reader sees `dplyr::filter` and knows immediately it's the dplyr verb.

### Typography — Futura body, robust fallback cascade, weight 400

**TL;DR:** Futura first with Mac→Windows fallback chain; body 400, bold 700, no serif hero pairing.

**Choice:** Body font cascade `'Futura', 'Futura PT', 'Avenir Next', 'Avenir', 'Trebuchet MS', sans-serif`; body weight 400; `<strong>`/`<b>` inherits browser default 700; hero stays in the same family at 700.

**Why:** Futura is available on macOS (Echo's primary editing platform) but not on Windows. The cascade gracefully degrades to Avenir Next (the closest macOS geometric sans), then Avenir, then Trebuchet MS (the only widely-installed geometric-leaning sans on Windows lab machines). Body weight 400 = Futura "Book", which reads cleanly on screen; bold tags keep their visual emphasis. A serif hero was considered and rejected — pairing a geometric sans body with a serif hero adds a typeface contrast on top of the existing size/weight/colour contrasts, which Tufte would describe as "type chartjunk" on a data dashboard.

**Bug fixed:** The earlier `.intro-narrative` block contained `font_weight: 100` (underscore instead of hyphen) and was silently ignored by every browser; removed during this pass so the body-level 400 cascades cleanly.

### Inline CSS rather than a separate `www/style.css`

**TL;DR:** One `woof_css` string injected into `<head>` keeps all styling visible in the single file.

**Choice:** A single `woof_css` string injected into `<head>` via `tags$head(tags$style(HTML(...)))`.

**Why:** Single-file app + every styled element visible in one place. Reducing the number of files in the submission zip also minimises the chance of a missing-file error on the marker's first run.

### Audience voice — plain, friendly, not academic

**TL;DR:** Write UI copy for NYC residents (dog owners/considerers), not academic readers — drop "indicates", "directly proportional", etc.

**Choice:** All user-facing copy (UI labels, tooltips, narrative paragraphs, callouts) uses plain second-person English in a friendly, factual register. No academic hedges, no slang, no exclamation marks.

**Why:** The DVP brief defines the target audience as NYC residents who own a dog or are considering one — not the marker, not academic readers. Echo's draft language for the Tab 2 interpretive paragraph ("indicates that bite counts are not directly proportional to dog population size") was rewritten as "So bite counts in a borough aren't just a function of how many dogs live there" — same finding, plainer voice. Confirmed as the project's voice when Echo accepted the polish and applied it to her own subsequent restructure.

**How to apply:** Default to the audience-voice version when drafting any user-facing copy. Echo reviews and overrides where needed.

### Tab reflection narrative pattern — house style

**TL;DR:** Below-chart reflection: `<h3>` lead + 1–2 paragraphs + three `<h4>` callouts (*Key takeaway* / *Important context* / *Continue exploring*) with a bulleted hand-off into the next tab(s).

**Choice:** Set on Tab 2 by Echo's restructure. Replicate on Tabs 3 and 4.

**Structure:**

1. `<h3>` lead heading — "What this chart reveals" or equivalent.
2. One or two prose paragraphs stating the headline finding and any secondary pattern.
3. `<h4> Key takeaway` — a one-paragraph compact statement of the main insight.
4. `<h4> Important context` — a caveat / data-limitation note.
5. `<h4> Continue exploring` — a sentence + bulleted list pointing to the next relevant tab(s) by bold name, with a closing sentence that ties them together.

**Why:** Follows the Setup → Visual → Reflection pattern (Segel & Heer 2010) but with sub-headings that let a scanner pick up the key takeaway without reading the prose. Bullet hand-off turns the bottom of each tab into a flow point into the next, supporting the multi-tab narrative arc.

**Reference:** Segel, E. & Heer, J. (2010). Narrative Visualization: Telling Stories with Data. *IEEE TVCG*, 16(6).

---

## Tab 1: Introduction

### Layout — heading + two-column body + KPI row

**TL;DR:** Hero question + 50/50 narrative-map split + three KPI cards. Author-driven hook before any analytical tab.

**What was built:** A hero question heading ("Are you a dog owner?"), a 50/50 fluidRow with project narrative on the left and a static borough reference map on the right, followed by three KPI summary cards across the bottom.

**Why this layout:**

- The opening question framing was retained from FDS Sheet 3 (scroll-narrative concept). It engages the reader emotionally before any data is shown — narrative-visualisation literature (Segel & Heer 2010) describes this as the "author-driven hook" that sets context before exploration.
- The 50/50 split places narrative and map in equal weight. Munzner's *why-axis*: the user needs *context* (narrative) and *spatial grounding* (map) in parallel before they can interpret the analytical tabs.
- KPI cards along the bottom satisfy the "headline numbers" requirement while remaining secondary to the map (which carries the spatial mental model the rest of the app depends on).

**Reference:** Segel, E. & Heer, J. (2010). Narrative Visualization: Telling Stories with Data. *IEEE TVCG*, 16(6).

### Static borough reference map (not interactive)

**TL;DR:** Plain ggplot, no Leaflet — the map's job here is orientation, not exploration.

**Choice:** A plain ggplot rendered via `renderPlot`, no Leaflet, no tooltips, no panning.

**Why:** The map's job on Tab 1 is *orientation* — telling the reader which shape each borough has and which colour represents it. Interaction would invite exploration on the one tab whose role is *introduction*. Tufte's data-ink principle applies: no interface affordance should be added without justification. Tabs 3 (Infrastructure) and 4 (Safety) carry the interactive maps; splitting roles between tabs reinforces Munzner's *what* axis (different abstract task per tab).

**Reference:** Tufte, E. (2001). *The Visual Display of Quantitative Information*, 2nd ed., Graphics Press.

### KPI values computed from data, not hard-coded

**TL;DR:** Every KPI is a one-expression read off the data, not a literal — marker can verify the source in one click.

**What was built:** Three KPIs at startup:

- `kpi_n_zctas` = `nrow(master_filtered)` → 182.
- `kpi_pct_zero_runs` = `mean(master_filtered$n_runs == 0)` → 64.8%.
- `kpi_top_bite_borough` = the borough with the highest *median* `bite_rate` (computed via group_by + summarise + arrange + slice(1)).

**Why:** Hard-coding would break silently if the underlying data were ever updated. Computing from data also means a marker asking "where does 64.8% come from?" can be answered by pointing at one expression. *Median* (not mean) is chosen for the bite-rate KPI so a single outlier ZCTA cannot determine the winner.

**Reference:** Munzner's principle of *abstraction* — the displayed value should be a function of the data, not a literal embedded in code.

### Custom `kpi_card()` helper rather than `bslib::value_box()`

**TL;DR:** Six-line in-file helper, no `bslib` dependency — everything visible in one place.

**Choice:** A six-line `kpi_card(value, label, accent)` helper returning a styled `<div>`.

**Why:** No package dependency for what amounts to a styled HTML block. Every line of the card's appearance is in `app.R` (the function in section 3d and the CSS in section 4), so the marker can read the function definition and the CSS and see exactly what each card is. This is more defensible than importing `bslib::value_box`, whose API has changed across versions.

---

## Tab 2: Trends

### Layout — hero question + sidebar filter + plotly chart

**TL;DR:** Hero question + `sidebarLayout` (left: checkbox filter; right: plotly line chart). All five boroughs pre-selected so the headline shows on first load.

**What was built:** A hero question heading ("How have bite incidents changed?") above an orienting sentence and a `sidebarLayout`. The left-side `sidebarPanel(width = 3)` holds a `checkboxGroupInput` with all five boroughs pre-selected; the right-side `mainPanel(width = 9)` holds the plotly chart.

**Why this layout:**

- Hero question parallels Tab 1's "Are you a dog owner?" — every tab opens with a question, which gives the five tabs a consistent narrative cadence (Segel & Heer 2010, *author-driven* segments inside a *reader-driven* shell).
- `sidebarLayout` puts the filter adjacent to the view it affects (Munzner: spatial juxtaposition of controls and view supports the user's mental model of cause and effect).
- All boroughs pre-selected by default so the headline trend is visible on first load — the *default state of an interactive view should already tell a story* (Cairo, *The Truthful Art*, 2016).

### Native `plot_ly()` over `ggplotly()`

**TL;DR:** ggplotly mangles `annotate("rect", ...)`; native plotly's `shapes` API is the documented stable path.

**Choice:** Constructed the Trends chart directly with `plot_ly()` and `layout(shapes = ..., annotations = ...)` rather than building a ggplot and converting via `ggplotly()`.

**Why:** `ggplotly()` translates most ggplot geoms but does not reliably translate `annotate("rect", ...)` — the COVID rectangle from the DEP-phase `p1b` design intermittently disappears or repositions in the converted JSON. Native plotly's `shapes` and `annotations` API is the documented stable path (`plotly.R` reference, *layout > shapes*), and gives clean per-trace control over `hovertemplate`.

**Trade-off acknowledged:** The native `plot_ly` syntax is less familiar than ggplot and introduces a second visualisation grammar in the codebase. Mitigated by extracting the shared chart skeleton (axes, COVID band, annotations, legend, modebar suppression) into a `tab2_apply_layout()` helper.

### Annotation layer — COVID band + 2020/2022 labels

**TL;DR:** Yellow rectangle 2019.5–2020.5 + two paper-anchored text labels — the finding is visible without hovering.

**What was built:** A yellow translucent rectangle spanning 2019.5–2020.5 on the x-axis with `yref = "paper"` so it always fills the full chart height; two text annotations at `y = 0.97` (paper coords) reading "COVID-19 drop" and "Recovery peak".

**Why:**

- Cairo's *annotation layer* principle: a reader who looks at the chart for two seconds without hovering should already see the finding. The rectangle + label do that; the tooltips add detail-on-demand on top.
- `yref = "paper"` (not data coordinates) means the band and labels stay correctly positioned even after the user filters boroughs and the max bite_count shrinks. Anchoring to data coordinates would cause the labels to drift up/down with the filtered max.
- `layer = "below"` keeps the COVID band behind the data lines so colour-coded lines remain the dominant visual.

**Reference:** Cairo, A. (2016). *The Truthful Art: Data, Charts, and Maps for Communication.* New Riders.

### Tooltip design — rich tooltip chosen after side-by-side comparison

**TL;DR:** Rich tooltip wins: Year + Borough title, bite count, year-on-year %, 2020/2022 context flag. Simple 3-line variant was prototyped in parallel and rejected.

**Choice:** A rich tooltip carrying *Year + Borough* as the title, then the bite count, then year-on-year percent change, and a context flag for 2020 ("COVID year") and 2022 ("Post-COVID peak"). A simpler 3-line variant (Year / Borough / Bites) was built in parallel as a comparison view and rejected.

**Why the rich variant won:** The COVID rectangle and the 2020/2022 chart-layer annotations already locate the story spatially; the tooltip's job is to supply the *quantitative* context that doesn't fit on the chart — specifically the year-on-year change, which is the most-asked question once a reader sees the dip. Showing −27% on the 2020 hover instead of just "1,423 bites" turns hover from a readout into a finding.

**Why a comparison view was used at all:** The "minimum necessary, maximum context" trade-off for tooltips has no general right answer — it depends on whether the chart's annotations already convey the story. Building both let us judge against the live chart instead of speculating.

**Implementation detail:** The hover string is pre-built in R (using `paste0` + `format(big.mark = ",", trim = TRUE)` + `ifelse(nzchar(note), ...)`) and fed to plotly via `text = ~tooltip_text` with `hovertemplate = "%{text}<extra></extra>"`. Building the string in R rather than in plotly's JS templating mini-language is cleaner for the conditional context-line logic. `<extra></extra>` suppresses plotly's default trace-name secondary box.

### YoY computed once at startup, not in the reactive

**TL;DR:** Static data → augment at load time, not in the reactive. *Split-phase* principle.

**Choice:** The `yoy_pct`, `yoy_label`, and `note` columns are added to `bites_per_year_borough` in section 2b (outside the server), not inside `selected_bites()`.

**Why:** The augmented frame is static for the life of the R session; recomputing on every checkbox click would be wasted work. This is a small instance of the *split phase* principle — perform all static work at startup, leave the reactive doing only the work that depends on user input (here, a single `filter()`).

**Implementation note:** `group_by(borough) |> arrange(year, .by_group = TRUE) |> mutate(yoy_pct = ... lag(...))` — the `arrange` must precede the `mutate` because `lag()` is positional. The 2016 row gets `yoy_label = "—"` (em dash) because there is no preceding year to lag against.

### Interpretive narrative below the chart — house style for tab reflections

**TL;DR:** `<h3>` lead + 2 paragraphs + 3 `<h4>` callouts (*Key takeaway* / *Important context* / *Continue exploring*) below the chart. Sets the house style for Tabs 3 & 4.

**What was built:** A multi-section reflection block in a single `.intro-narrative` div placed BELOW the `sidebarLayout`:

1. `<h3>` lead heading: "What this chart reveals".
2. Lead paragraph stating the Queens-highest finding and framing it as evidence that bite counts aren't a simple function of dog population (neighbourhood environment, public space design, dog-owner behaviour).
3. Second paragraph covering the 2020 COVID drop and the 2022/2023 recovery.
4. `<h4> Key takeaway` — "Dog safety is not simply about 'more dogs equals more bites.'"
5. `<h4> Important context` — caveat that figures are absolute counts, not rates, because licensing data is missing for 2019–2021.
6. `<h4> Continue exploring` — sentence + bulleted list pointing to **Infrastructure** and **Safety** tabs by bold name, with a closing sentence that ties them together ("infrastructure access, density, and socio-economic conditions...").

**Why this exists, and why it sits below the chart:** Narrative-visualisation work (Segel & Heer 2010) describes the *Setup → Visual → Reflection* structure as one of the most-effective patterns for analyst-targeted reading: orient the reader, show the data, then explicitly state what to take away. Tab 2's orienting sentence above the chart handles *setup*; the chart is the *visual*; this block is the *reflection*. Placing reflection AFTER the chart matters: a reader sees the data first and reads the interpretation against their own first impression, rather than having the interpretation prime their reading of the chart.

**Why sub-headings instead of flat paragraphs:** The original draft was four flat `<p>` paragraphs. Echo restructured them into `<h3>` + paragraphs + `<h4>` callouts so a scanner can pick up *Key takeaway* / *Important context* / *Continue exploring* without reading every paragraph. This is the pattern that will be replicated on Tabs 3 and 4.

**Reference:** Segel, E. & Heer, J. (2010). Narrative Visualization: Telling Stories with Data. *IEEE TVCG*, 16(6).

---

## Tab 3: Infrastructure

### Layout — sidebarLayout mirror of Tab 2

**TL;DR:** Same `sidebarLayout(3/9)` as Tab 2 — radio toggle on the left, leaflet on the right. The DVP2_UI right-narrative-panel was deliberately not replicated, to keep the interactive grammar consistent across tabs.

**Choice:** `sidebarLayout(sidebarPanel(width = 3, radioButtons(...)), mainPanel(width = 9, leafletOutput(...)))`. The 2–3 sentence orienting note sits *above* the map in an `.intro-narrative` div, the same way Tab 2's orienting sentence does. The full reflection block sits below the map.

**Why:** Munzner's *spatial-juxtaposition-of-controls-and-view* principle is satisfied by sidebarLayout. More importantly, keeping the same control-left-view-right grammar on every analytical tab gives the app one cognitive pattern instead of three; once the reader has decoded the Tab 2 layout, Tab 3 is the same shape with a different visual. Building a fluidRow-and-overlay variant for one tab only would add a third layout idiom without payoff.

**Reference:** Munzner, T. (2014). *Visualization Analysis & Design*, ch. 12 *Facet Into Multiple Views*.

### Two-palette toggle — plasma for density, viridis for gap

**TL;DR:** Distinct hue families (warm plasma, cool viridis) instead of two shades of one ramp. The user can tell at a glance which view is active without checking the legend.

**Choice:** `viridisLite::plasma(256)` for the density choropleth, `viridisLite::viridis(256)` for the gap-index choropleth. Both are perceptually uniform across their domain and remain monotonic under deuteranopia.

**Why:** A common alternative for a two-state toggle is "the same palette, lighter vs darker." That collapses the *which view is active* signal onto the same channel that encodes the data, which makes the toggle ambiguous. Splitting into warm-vs-cool hue families gives the toggle a free, pre-attentive channel — Bertin's *colour hue* — separate from the *colour value* doing the data work. The colour-vision safety properties of both palettes also satisfy our Okabe-Ito-equivalent guarantee on the quantitative side.

**Reference:** Crameri, F., Shephard, G. E. & Heron, P. J. (2020). The misuse of colour in science communication. *Nature Communications*, 11, 5444.

### Sqrt transform on `dog_density` only

**TL;DR:** Density is right-skewed (dense Manhattan vs sparse Staten Island), so the palette is fitted on `sqrt(dog_density)` and the legend back-transforms with `labelFormat(transform = function(x) x^2)`. `gap_index` is left untransformed because it already sits in [0, 1].

**Choice:** `pal_density <- colorNumeric(palette = plasma(256), domain = sqrt(master_filtered$dog_density))`. The same `sqrt()` is applied to actual values at render time: `fillColor = pal_density(sqrt(dog_density))`. The legend's `labFormat` carries `transform = function(x) x^2` so displayed ticks read in dogs/km² rather than sqrt units.

**Why:** Without a transform, a handful of very dense ZCTAs dominate the upper end of the colour ramp and the entire outer-borough is mapped to the dark low-density end. Sqrt is the conservative monotonic correction (log would over-correct and risk compressing the high end past readability). The colour ramp ends up perceptually uniform in sqrt-space — visually equal colour bands correspond to equal *sqrt(density)* jumps. The label back-transform is intentional: the ramp is uniform in sqrt-space (which is what the eye reads), and the labels honestly tell the user where the breakpoints land in real density units.

**Reference:** Cleveland, W. S. (1985). *The Elements of Graphing Data*. Wadsworth. Also Munzner, *Visualization Analysis & Design*, ch. 6 on non-linear scales for skewed quantitative attributes.

### Time-horizon mismatch — density 2022 vs bite_rate cumulative

**TL;DR:** `dog_density` in the rds is a 2022-only snapshot (DEP wrangling line 853); `bite_rate` elsewhere is the cumulative 2016–2023 measure. The two metrics deliberately answer different kinds of question. Acknowledged in the Tab 3 "Important context" callout and in the tooltip label, which reads "Dog density (2022)".

**Choice:** Keep `dog_density` as the 2022 snapshot the rds already holds, rather than recomputing it as cumulative.

**Why:** Density is a *present-state* question (how packed is this neighbourhood now, given fixed park geometry), while bite_rate is a *cumulative outcome* (total bites accumulated across the panel). Recomputing density to cumulative would also force a recomputation of `gap_index`, which was constructed on top of the 2022 density in the DEP wrangling — diverging from the DEP submission with no analytical benefit. The honest move is to keep the metric the rds defines and label it explicitly.

**Trade-off acknowledged:** A naive reader might assume both metrics share a time horizon. The "Important context" callout below the map names the difference explicitly. The tooltip label "Dog density (2022)" reinforces this on hover.

### `renderLeaflet` + `leafletProxy` pattern

**TL;DR:** Base map (tiles + view + 91 circle markers) is drawn once via `renderLeaflet`. The choropleth layer and legend are swapped on every radio click via `leafletProxy` — no tile re-fetch, no marker re-render, no view reset.

**Choice:** `output$tab3_map <- renderLeaflet({ ... })` builds tiles + `setView` + `addCircleMarkers`. `observeEvent(input$tab3_metric, { leafletProxy("tab3_map") |> clearGroup("choropleth") |> clearControls() |> addPolygons(...) |> addLegend(...) })` mutates only the polygon layer + legend. Polygons are tagged `group = "choropleth"`, markers are tagged `group = "dog_runs"`, so `clearGroup("choropleth")` doesn't touch the markers.

**Why:** Re-running `renderLeaflet` on every toggle click would re-fetch tiles from CartoDB, re-render all 91 markers, and reset the user's zoom/pan. The proxy pattern is the documented Shiny-leaflet idiom for partial updates — *Modifying Existing Maps with leafletProxy* in the leaflet R package vignette. Crucially, naming the choropleth and the markers with distinct `group` strings is what makes the partial update safe.

**Reference:** Cheng, J. et al. *leaflet for R*, vignette "leaflet-shiny.Rmd": https://rstudio.github.io/leaflet/shiny.html

### CartoDB Positron basemap

**TL;DR:** Low-contrast greyscale tiles via `addProviderTiles(providers$CartoDB.Positron)`. Lets the choropleth fill carry the colour story without tile texture competing.

**Choice:** `addProviderTiles(providers$CartoDB.Positron, options = providerTileOptions(opacity = 0.95))`.

**Why:** Thematic choropleth design requires the underlying basemap to fade into background so the data layer is the dominant visual. The standard alternatives — OpenStreetMap, OpenStreetMap.Mapnik — are too saturated and compete with the plasma/viridis fills, particularly at viridis's darker low-gap end. Positron is the recommended low-contrast tile set for thematic mapping and is the same pairing FIT5147 Week 9 Applied uses in its leaflet examples.

### Circle markers over paw icons — decision resolved

**TL;DR:** `addCircleMarkers`, neutral dark dot (`#1F2933`), white halo, radius 4. Borough is already encoded by the polygon underneath, so colouring the markers by borough would be redundant.

**Choice:** Confirmed circle markers over the DVP2_UI paw-icon variant.

**Why:** The DVP2_UI mockup showed paw-icons, but in the live app these would (a) require an external PNG asset bundled into the project zip, increasing the chance of a missing-file error on the marker's first run; (b) be harder hit-targets in dense run clusters around Central Park; and (c) clash visually against the plasma/viridis fills depending on toggle. Circle markers in a neutral dark grey read cleanly against both palettes, need no external asset, and stay legible at the city-wide zoom level. The marker's job here is *location*, not *iconography* — Munzner: *don't encode what position already encodes*.

### Tooltip design — hover `label` on polygons, click `popup` on markers

**TL;DR:** Polygons get a lightweight hover label with five fields (ZIP, borough, dog density, # runs, gap index). Markers get a click-to-pin popup with the park name and borough.

**Choice:** Two distinct leaflet affordances mapped to two distinct entity types — `label` for statistical regions you scan over, `popup` for named entities you stop on.

**Why:** This is the leaflet idiom: *labels are for context, popups are for content*. A reader skims the choropleth and wants to spot-check what colour means without committing a click; a click on a named place (a specific run) is a deliberate stop and warrants a pinned popup. The two affordances differ visually too — labels follow the cursor and dismiss on move; popups stay pinned until dismissed.

**Implementation detail:** `tab3_polygon_labels` is built once at startup as a `list(htmltools::HTML(...), ...)` of length `nrow(master_filtered)`. Pre-building is the same split-phase rationale as the Trends `yoy_label` — `master_filtered` is static for the R session, so rebuilding labels on every render is wasted work. `htmltools::HTML` is used so the embedded `<br>`, `<strong>`, and `<sup>` tags render rather than print as literal text.

### Highlight-on-hover — border only, not fill

**TL;DR:** `highlightOptions(weight = 2, color = "#1F2933", bringToFront = TRUE)` — thicker dark border on hover, no fill colour change.

**Choice:** Border thickens from 0.5 to 2 and goes near-black on hover. The fill colour stays exactly as encoded by the palette.

**Why:** Changing the fill colour on hover destroys the colour encoding *while the reader is reading it*. They moved the cursor onto a polygon specifically to read its colour-encoded value; replacing that colour with a highlight tint defeats the entire purpose. Border thickening achieves the same "this is the one your cursor is on" signal without touching the colour channel.

**Reference:** Munzner, *Visualization Analysis & Design*, ch. 11: interactive linking should support, not disrupt, the static encoding.

### Observer structure — branch-free rendering

**TL;DR:** Bind the four metric-specific values (`fill_values`, `pal_fn`, `legend_title`, `legend_format`) at the top of the observer, then make a single `addPolygons + addLegend` call. Avoids duplicating 15 lines of polygon styling across two if-branches.

**Choice:** A short `is_density <- input$tab3_metric == "density"` followed by four `if (is_density) ... else ...` bindings, then one call chain.

**Why:** A naive implementation has two complete `addPolygons(...) |> addLegend(...)` calls inside an `if/else`, where 90% of the lines are identical (weight, colour, fillOpacity, label, labelOptions, highlightOptions, group, position, opacity). Factoring the differences into four named variables keeps the rendering chain in one place — a reader can see *what changes per metric* at the top of the observer, and *how the rendering works* below, instead of diffing two near-identical branches.

### `dplyr::case_match()` over `dplyr::recode()`

**TL;DR:** Borough-code translation (`M` → `Manhattan`, etc.) uses `dplyr::case_match()`. `dplyr::recode()` is in "questioning" status in modern dplyr.

**Choice:** `dplyr::case_match(BOROUGH, "M" ~ "Manhattan", "B" ~ "Brooklyn", "Q" ~ "Queens", "X" ~ "Bronx", "R" ~ "Staten Island")` inside the dog-run loading pipe.

**Why:** `dplyr::recode()` works but is soft-deprecated (it prints a "questioning" lifecycle warning in some setups). `case_match()` is the modern idiom (dplyr ≥ 1.1.0, January 2023). Available in R 4.5.2 with current dplyr. Same call style as `case_when` so the rest of the codebase stays consistent.

---

## Tab 4: Safety

*Pending — to be populated when this tab is built.*

**Open decision before building:** narrative placement — one paragraph below both views, or a sentence-level insight near the heading? Likely answer: follow the Tab 2 house style (full reflection block below both views).

---

## Tab 5: About

*Pending — to be populated when this tab is built.*

---

## Open items for next session

- **Tab 4 (Safety) narrative** — confirm Tab 2 / Tab 3 house style applies, or call out a deliberate departure. Open sub-question: whether Tab 4 also wants a sentence-level insight near the heading *in addition to* the below-views reflection block (per the original handover note).
- **Tab 4 (Safety) build** — bite-rate choropleth (rocket palette, reversed; full pattern mirrors Tab 3) + income-vs-bite-rate plotly scatter coloured by borough. Reuses the Tab 3 leafletProxy idiom and the Tab 2 plot_ly idiom.
- **Tab 5 (About)** — data sources listed with URLs, how-to-use the app, student credit + copyright line.
- **Final verification pass** — clean R session, end-to-end run, tab navigation, hover/filter responsiveness, palette consistency. Exclude `.Rproj.user/` when zipping.
