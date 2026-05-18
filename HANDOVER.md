# Woof! New York — Chat Handover Prompt

*Self-contained continuity document. Paste this (or the path to it) at the top of any future chat to resume the DVP Part 2 build without re-reading the full history.*

---

## Who I am
I am **Wanting (Echo) Zhao**, Student ID 35507071, FIT5147 S1 2026, Monash University. Applied Session 12. Teaching Associates: Ashwini Narasimhan & Mohit Gupta. You are my **personal tutor** for the DVP Part 2 build.

## Working style — please follow
- Step-by-step: plan → check outputs → adjust → document.
- Explain every non-obvious line of code BEFORE writing it.
- Only produce code I can personally explain and defend (academic integrity at Monash is strict).
- Push back on weak choices — I respond well to critical pushback.
- Use the AskUserQuestion tool when there is a genuine ambiguous decision; otherwise, propose a default and let me override.

## What we're building
**"Woof! 🐾 New York"** — a 5-tab R Shiny narrative visualisation for NYC residents who own a dog or are considering getting one. Tells three stories: how bite incidents shifted around COVID, where the off-leash-infrastructure gap is widest, and how bite rate relates to neighbourhood income.

Sheet 5 specification: `/Users/ez_us/Documents/5147/DVP/DVP1to2handover.md`, layout mockups in `/Users/ez_us/Documents/5147/DVP/DVP2_UI.pdf` (6 pages, one per tab).

R environment: R 4.5.2, single-file `app.R`. Packages: shiny, sf, dplyr, readr, leaflet, plotly, ggplot2. No tidyverse.

## File map — where everything lives
Working directory: `/Users/ez_us/Documents/5147/DVP/woof_ny_app/`

- `app.R` — the single-file Shiny app.
- `woof_ny_app.Rproj` — opens the project in RStudio with the right working directory.
- `data/cleaned/master_filtered.rds` — 182 ZCTAs, sf, EPSG:4326. Columns include `zipcode`, `borough`, `dog_density`, `gap_index`, `median_income`, `n_runs`, `dogs_2022`, `total_dogs`, `total_bites`. NOTE: the `bite_rate` column in this rds is the *2022-only* version; we drop and recompute inside `app.R`.
- `data/cleaned/bites_per_year_borough.rds` — columns `year`, `borough`, `bite_count`. For Tab 2.
- `data/raw/Dog_Runs.csv` — 91 off-leash parks. Columns include `NAME`, `BOROUGH` (M/B/Q/X/R codes), `the_geom` (WKT MULTIPOLYGON).
- `notes_for_report.md` — design-decisions log. Drives Sections 2 and 3.2 of the DVP report. Now has a top-of-file Build Status table, a Session Log, and per-tab sections with one-line TL;DRs on every entry. Append a new session-log entry + new per-tab decisions after every tab is signed off.
- `HANDOVER.md` — this file. Update the "What's already built" and "Open items" sections after each tab.

DEP reference material (read-only; do not modify):
- `/Users/ez_us/Documents/5147/DVP/DEP_overview/DEP_DV_combined.R` — full wrangling + Phase-3 exploration script; existing ggplot designs to port.
- `/Users/ez_us/Documents/5147/DVP/DVP1/Wanting_35507071_Presentation.pdf` and `..._speaking_script.pdf` — submitted DVP1 materials.
- `/Users/ez_us/Documents/5147/DVP/FIT5147_DataVisualisationProject S1 2026.pdf` — official brief and rubric.

## Critical decisions already made — do NOT revisit unless I ask

1. **Single-file `app.R`**, no `ui.R` / `server.R` / `global.R` split.
2. **Bite rate** = cumulative `total_bites / total_dogs * 1000` across 2016–2023, recomputed at app start. Label everywhere: *"Bite rate (per 1,000 licensed dogs, cumulative 2016–2023)"*. Never "2022 rate".
3. **Borough palette: Okabe-Ito (2008)**:
   - Manhattan `#0072B2`, Brooklyn `#CC79A7`, Queens `#E69F00`, Bronx `#009E73`, Staten Island `#D55E00`.
   - Reason: deuteranopia-safe, citable (Wong, *Nature Methods* 2011).
4. **KPI values computed from data**, not hard-coded.
5. **dplyr verbs namespaced** (`dplyr::filter`, etc.) because `plotly::filter` shadows.
6. **Custom `kpi_card()` helper** instead of `bslib::value_box`, to avoid an extra dependency.
7. **Inline CSS** (`woof_css` string injected via `tags$head(tags$style(HTML(...)))`), not a separate stylesheet.
8. **Typography: Futura-first body** with cascade `'Futura', 'Futura PT', 'Avenir Next', 'Avenir', 'Trebuchet MS', sans-serif`; body weight 400; hero stays in same family at 700 (no serif pairing).
9. **Tab reflection narrative pattern**: `<h3>` lead heading ("What this chart tells you?" / equivalent) + 1–2 narrative paragraphs + three `<h4>` callout sections (*Key takeaway*, *Important context*, *Continue exploring*) with a bulleted hand-off into the next relevant tab(s). All inside a single `.intro-narrative` div below the chart. Replicate on Tabs 3 & 4.
10. **Audience voice for user-facing copy**: NYC residents who own a dog or are considering one — plain second-person language, drop academic hedges like "indicates" / "directly proportional". Apply to all UI copy, tooltips, narratives.

## What's already built

- [x] Project skeleton: `navbarPage()` with five `tabPanel()`s (Intro / Trends / Infrastructure / Safety / About).
- [x] Data loading: `master_filtered`, `bites_per_year_borough`, `dog_runs`. Bite-rate recompute applied. `bites_per_year_borough` now augmented at load with `yoy_pct`, `yoy_label`, `note` columns for the Trends rich tooltip.
- [x] Constants section: `borough_colours` (Okabe-Ito), `nyc_boroughs_map`, `borough_centroids`, three KPI values, `kpi_card()` helper, `tab2_apply_layout()` helper.
- [x] CSS section: peach navbar, orange hero heading, intro-narrative styling, KPI-card styling. **Typography fixed**: Futura-first cascade (`'Futura', 'Futura PT', 'Avenir Next', 'Avenir', 'Trebuchet MS', sans-serif`), body weight 400, `.intro-narrative` font-size 15px, `font_weight: 100` typo removed.
- [x] **Tab 1 (Introduction)** fully built: hero heading, two-column narrative + static ggplot borough reference map, three KPI cards across the bottom.
- [x] **Tab 2 (Trends)** fully built: hero "How have bite incidents changed?", checkbox borough filter on left, plotly line chart with rich tooltip (Year/Borough — bites, YoY %, COVID-year/Post-COVID-peak flag). COVID-19 yellow band 2019.5–2020.5 + "COVID-19 drop" and "Recovery peak" annotations on the chart layer. Native `plot_ly()` over `ggplotly()` because `annotate("rect", ...)` doesn't translate reliably. Interpretive narrative below the chart ("What this chart tells you" `<h3>` lead + two narrative paragraphs + three `<h4>` callouts: *Key takeaway*, *Important context*, *Continue exploring* with bulleted hand-off into Tabs 3 & 4). This multi-callout narrative shape is now the house style for tab reflections — Tabs 3 & 4 should follow the same structure.
- [x] **Tab 3 (Infrastructure)** fully built: hero "Where do dogs live, and where can they run?", `sidebarLayout(3/9)` mirroring Tab 2 — radio toggle on the left (*Dog density* default, *Gap index*), `leafletOutput("tab3_map", height = "520px")` on the right. **Two-part rendering**: `renderLeaflet` draws the base map once (CartoDB Positron tiles, `setView` to NYC, 91 `addCircleMarkers` in neutral dark grey with white halo, `popup = NAME + borough`); `observeEvent(input$tab3_metric, ...)` uses `leafletProxy` + `clearGroup("choropleth")` + `clearControls()` to swap the choropleth + legend without re-rendering markers or re-fetching tiles. **Palettes**: plasma fitted on `sqrt(dog_density)` for density (legend back-transforms with `labFormat = labelFormat(transform = function(x) x^2, digits = 0, big.mark = ",")` so ticks read in dogs/km²), viridis for `gap_index` (no transform — already in [0, 1]). **Polygon hover labels** (`tab3_polygon_labels`) pre-built once at startup as `lapply(...) → list(htmltools::HTML(...))` — ZIP, borough, "Dog density (2022)", off-leash runs, gap index. **Highlight on hover** = border thickening (`weight = 2`, `#1F2933`) only — no fill change, to preserve the colour encoding. House-style reflection block below the map: "What this map reveals" → 2 paragraphs → *Key takeaway* / *Important context* / *Continue exploring* with bulleted hand-off into Tabs 4 & 2. **Library additions**: `viridisLite`. **dplyr verb**: `dplyr::case_match()` (not `recode`) translates dog-run `BOROUGH` codes (`M/B/Q/X/R`) to full names — modern dplyr ≥ 1.1.0 idiom. **Acknowledged time-horizon mismatch**: `dog_density` in the rds is the 2022-only snapshot, `gap_index` was built on it, and `bite_rate` is cumulative — called out in the Important-context callout and in the tooltip label.

## What's left
- [ ] **Tab 4 (Safety)** — Left 60%: leaflet choropleth of `bite_rate` (rocket palette, direction = −1). Hover tooltip: zipcode, borough, bite_rate, median_income. Right 40%: plotly scatter `median_income` vs `bite_rate`, coloured by borough. Narrative text below.
- [ ] **Tab 5 (About)** — data sources listed with URLs, how-to-use the app, student name + project credit + copyright line.
- [ ] **Final verification pass** — clean R session, run end-to-end, check tab navigation / hover tooltips / filter responsiveness / palette consistency. Exclude `.Rproj.user/` when zipping for submission.

## Open decisions for next session

- **Tab 4 narrative** — default is the house style (locked decision #9). Open: whether Tab 4 also wants a sentence-level insight near the heading *in addition to* the below-views reflection block.
- **Tab 4 left-right split** — handover spec says 60/40 (map / scatter). With the left sidebar removed (no equivalent of the borough-checkbox filter), the layout is a plain `fluidRow(column(width = 7, leafletOutput), column(width = 5, plotlyOutput))` rather than `sidebarLayout`. Confirm width split when building.

## How to resume — first message to the new chat

> Continue the Woof! NY DVP Part 2 build. Read
> `/Users/ez_us/Documents/5147/DVP/woof_ny_app/HANDOVER.md` first to load
> state — that file lists what's built, what's left, and the decisions
> we've already locked in. Today we tackle **Tab 4 (Safety)**.

After reading HANDOVER.md, your first action should be to inspect the current `app.R` so you know the existing patterns before writing new ones — especially the Tab 3 `renderLeaflet` + `leafletProxy` pattern and the Tab 2 `plot_ly` pattern, both of which Tab 4 will reuse. Then propose what you want to build for the next tab in prose (with the unit-material references) before writing any code, per my working style.
