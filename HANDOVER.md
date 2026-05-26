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

Sheet 5 specification: `/Users/ez_us/Documents/5147/DVP/DVP1to2handover.md`, layout mockups in `/Users/ez_us/Documents/5147/DVP/DVP2_UI.pdf` (6 pages, one per tab).One new layout mockup in `/Users/ez_us/Documents/5147/DVP/woof_ny_app/Safety_new.png` to align with current `app.R` code.

R environment: R 4.5.2, single-file `app.R`. Packages: shiny, sf, dplyr, readr, leaflet, plotly, ggplot2. No tidyverse.

## File map — where everything lives
Working directory: `/Users/ez_us/Documents/5147/DVP/woof_ny_app/`

- `app.R` — the single-file Shiny app.
- `woof_ny_app.Rproj` — opens the project in RStudio with the right working directory.
- `data/cleaned/master_filtered.rds` — 182 ZCTAs, sf, EPSG:4326. Columns include `zipcode`, `borough`, `dog_density`, `gap_index`, `median_income`, `n_runs`, `dogs_2022`, `total_dogs`, `total_bites`. NOTE: the `bite_rate` column in this rds is the *2022-only* version; we drop and recompute inside `app.R`.
- `data/cleaned/bites_per_year_borough.rds` — columns `year`, `borough`, `bite_count`. For Tab 2.
- `data/raw/Dog_Runs.csv` — 91 off-leash parks. Columns include `NAME`, `BOROUGH` (M/B/Q/X/R codes), `the_geom` (WKT MULTIPOLYGON).
- `notes_for_report.md` — design-decisions log. Drives Sections 2 and 3.2 of the DVP report. Now has a top-of-file Build Status table, a Session Log, and per-tab sections with one-line TL;DRs on every entry. Append a new session-log entry + new per-tab decisions after every tab is signed off.
- `tab5_v1.r` — parked first draft of the Tab 5 (About) markup, before Echo trimmed it. Reference only; not sourced by `app.R`.
- `HANDOVER.md` — this file. Update the "What's already built" and "Open items" sections after each tab.
- `/Users/ez_us/Documents/5147/DVP/wanting_35507071_DVP_report.md` — the DVP Part 2 written-report draft (the next workstream). Lives in the parent DVP folder, not the app folder.

DEP reference material (read-only; do not modify):
- `/Users/ez_us/Documents/5147/DVP/DEP_overview/DEP_DV_combined.R` — full wrangling + Phase-3 exploration script; existing ggplot designs to port.
- `/Users/ez_us/Documents/5147/DVP/DEP_overview/DEP2_ZHAOWANTING-35507071.pdf` — Echo's submitted DEP Part 2 report. Source of truth for: dataset URLs (Section 2.1), wrangling steps (Section 2.2), the Q3 rocket-palette decision the Safety tab inherits, and the AI-tool declaration (Section 5) to adapt for the **report's** end declaration (it lives in the report, not the app).
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
10. **Audience voice for user-facing copy**: NYC residents who own a dog or are considering one — *plus* anyone else in their household, child to grandparent. Plain second-person where natural, but reflection-block `<h3>`s now use inclusive "us" rather than directive "you" (e.g. *"What this map tells us"*, not *"What this map tells you"*). Drop academic hedges like "indicates" / "directly proportional"; prefer short concrete sentences a reader of any age can follow. Apply to all UI copy, tooltips, narratives. (Polished further on 2026-05-19.)
11. **Accessibility baseline** (set 2026-05-21): nav text colour must clear WCAG AA contrast (≥ 4.5:1 normal, ≥ 3:1 large/bold) — the active tab is dark `#1F2933` on orange `#E69F00` (6.55:1), **not** white-on-orange (2.25:1, fails). Keyboard-focus rings stay visible (`outline: 3px solid #0072B2`). Interactive hover feedback leads with a non-colour channel (border weight), never by recolouring the fill. Navbar is `position: fixed`. Don't regress these when restyling.

## What's already built

- [x] Project skeleton: `navbarPage()` with five `tabPanel()`s (Intro / Trends / Infrastructure / Safety / About).
- [x] Data loading: `master_filtered`, `bites_per_year_borough`, `dog_runs`. Bite-rate recompute applied. `bites_per_year_borough` now augmented at load with `yoy_pct`, `yoy_label`, `note` columns for the Trends rich tooltip.
- [x] Constants section: `borough_colours` (Okabe-Ito), `nyc_boroughs_map`, `borough_centroids`, three KPI values, `kpi_card()` helper, `tab2_apply_layout()` helper.
- [x] CSS section: peach navbar, orange hero heading, intro-narrative styling, KPI-card styling. **Typography fixed**: Futura-first cascade (`'Futura', 'Futura PT', 'Avenir Next', 'Avenir', 'Trebuchet MS', sans-serif`), body weight 400, `.intro-narrative` font-size 15px, `font_weight: 100` typo removed.
- [x] **Tab 1 (Introduction)** fully built: hero heading, two-column narrative + static ggplot borough reference map, three KPI cards across the bottom.
- [x] **Tab 2 (Trends)** fully built: hero "How have bite incidents changed?", checkbox borough filter on left, plotly line chart with rich tooltip (Year/Borough — bites, YoY %, COVID-year/Post-COVID-peak flag). COVID-19 yellow band 2019.5–2020.5 + "COVID-19 drop" and "Recovery peak" annotations on the chart layer. Native `plot_ly()` over `ggplotly()` because `annotate("rect", ...)` doesn't translate reliably. Interpretive narrative below the chart ("What this chart tells you" `<h3>` lead + two narrative paragraphs + three `<h4>` callouts: *Key takeaway*, *Important context*, *Continue exploring* with bulleted hand-off into Tabs 3 & 4). This multi-callout narrative shape is now the house style for tab reflections — Tabs 3 & 4 should follow the same structure.
- [x] **Tab 3 (Infrastructure)** fully built: hero "Where do dogs live, and where can they run?", `sidebarLayout(3/9)` mirroring Tab 2 — radio toggle on the left (*Dog density* default, *Gap index*), `leafletOutput("tab3_map", height = "520px")` on the right. **Two-part rendering**: `renderLeaflet` draws the base map once (CartoDB Positron tiles, `setView` to NYC, 91 `addCircleMarkers` in neutral teal `#40B0A6` with white halo, `popup = NAME + borough`); `observeEvent(input$tab3_metric, ...)` uses `leafletProxy` + `clearGroup("choropleth")` + `clearControls()` to swap the choropleth + legend without re-rendering markers or re-fetching tiles. **Palettes**: plasma fitted on `sqrt(dog_density)` for density (legend back-transforms with `labFormat = labelFormat(transform = function(x) x^2, digits = 0, big.mark = ",")` so ticks read in dogs/km²), viridis for `gap_index` (no transform — already in [0, 1]). **Polygon hover labels** (`tab3_polygon_labels`) pre-built once at startup as `lapply(...) → list(htmltools::HTML(...))` — ZIP, borough, "Dog density (2022)", off-leash runs, gap index. **Highlight on hover** = border thickening (`weight = 2`, `#1F2933`) only — no fill change, to preserve the colour encoding. House-style reflection block below the map: heading polished to "What this map tells us" on 2026-05-19, then 2 paragraphs → *Key takeaway* / *Important context* / *Continue exploring* with bulleted hand-off into Tabs 4 & 2. **Library additions**: `viridisLite`. **dplyr verb**: `dplyr::case_match()` (not `recode`) translates dog-run `BOROUGH` codes (`M/B/Q/X/R`) to full names — modern dplyr ≥ 1.1.0 idiom. **Acknowledged time-horizon mismatch**: `dog_density` in the rds is the 2022-only snapshot, `gap_index` was built on it, and `bite_rate` is cumulative — called out in the Important-context callout and in the tooltip label.
- [x] **Tab 4 (Safety)** fully built: hero "Does where you live shape how safe it is?". **Two-row layout** (Echo's restructure on 2026-05-19 replaced the initial 7/5 single-row design): **Row 1** is a 7/5 split — `leafletOutput("tab4_map", height = "500px")` on the left, a *map-specific* narrative block on the right (`<h3>` "What this map suggests?" + 3 short paragraphs + a `<h4>` "Before moving down" prompt). **Row 2** is a full-width `plotlyOutput("tab4_scatter", height = "500px")` — the scatter was moved out of row 1 because the 5-column variant overlapped dots in the high-income / low-bite cluster and hover targets were too small. **Map**: single `renderLeaflet` (no toggle, so no `leafletProxy` split), `pal_bites = colorNumeric(viridisLite::rocket(256, direction = -1))` so dark red = high bite rate, white hairline borders, `fillOpacity = 0.7`, `na.color = "#EEEEEE"` + `na.label = "No data"` on the legend, `tab4_polygon_labels` (ZIP / borough / bite rate / cumulative-2016–2023 qualifier / median income). **Scatter**: native `plot_ly`, `mode = "markers"`, `color = ~borough` with `colors = borough_colours`, 0.5px white halo around each marker (Cleveland overplotting fix), `tickformat = "$,d"` on x, `rangemode = "tozero"` on y, **legend rotated horizontal** above the chart (`orientation = "h", x = 0, y = 1.12`, top margin bumped to `t = 70`) because the full-width canvas left no room for a side legend. No trendline — confirmed design call, see *Open decisions* below. Bottom reflection block follows the house style: `<h3>` lead + paragraph (scatter-only now that the map has its own narrative beside it) + *Key takeaway* / *Important context* / *Continue exploring* with hand-off into Infrastructure and Trends. **`tab4_scatter_data`** is pre-built once at startup: `st_drop_geometry()` (so plotly does not serialise 182 MULTIPOLYGONs into the page JSON) + `filter(!is.na(median_income), !is.na(bite_rate))` (NA ZCTAs stay on the map as grey "No data"; they're dropped from the scatter to keep per-borough marker counts honest) + a pre-built `tooltip_text` string.
- [x] **Tab 5 (About)** fully built: hero "About this project" + a single `.intro-narrative` div. Sections: one-paragraph project blurb → **Data sources** `<h3>` with a **five**-item bulleted list (dataset name + agency + external link; A–E only — Dataset F / ACS Borough Population is excluded because the running app never reads it) → **Credits** one-liner → **Source code** list (DEP + DVP GitHub repos) → **Acknowledgements** (teaching team) → `<hr>` → `<small>` copyright with a dynamic year via `format(Sys.Date(), "%Y")`. **No "How to use" section** (Intro + per-tab narration already guide interaction) and **no in-app AI declaration** (the brief requires it in the report, not the app). Reflection-block house style deliberately not used (no chart on this tab). Every `tags$a` hardened with `target="_blank"` + `rel="noopener noreferrer"`. The fuller first draft is parked in `tab5_v1.r`.
- [x] **App-wide accessibility & navbar pass** (2026-05-21): navbar pinned (`position: fixed` + `body { padding-top: 70px }`) so tabs stay reachable after scrolling; keyboard-focus ring (`outline: 3px solid #0072B2`) on links/buttons/leaflet shapes; active-tab nav contrast corrected to dark `#1F2933` on orange `#E69F00` (6.55:1, passes WCAG AA — an earlier white-on-orange pass was 2.25:1 and failed); hover `fillOpacity = 0.9` now on **both** choropleths (Tabs 3 & 4), border-weight remaining the primary non-colour cue and fill hue never changing.

## What's left

- [x] **Report (DVP Part 2 written report)** — first full draft complete at `/Users/ez_us/Documents/5147/DVP/wanting_35507071_DVP_report.md`: Sections 1–4, Appendix scaffold, APA bibliography, and the AI-tool declaration in the "co-work with Claude ai" framing. Section 2 carries a design-process narrative (2.1, across the FdS sheets) plus thematic justification (2.2–2.9). Section 3.2 embeds the seven app screenshots as Figures 1–5 (3a/3b, 4a/4b).
- [x] **Showcase PDF** — `/Users/ez_us/Documents/5147/DVP/Wanting_35507071_DVP_report.pdf`, generated via Pandoc + XeLaTeX (clean academic style, subtle Woof-orange accents, TOC, page numbers). Reusable, commented build files live in `/Users/ez_us/Documents/5147/DVP/report_build/` (`build_report.sh`, `header.tex`, `titlepage.tex`, `README.md`). Re-run `bash report_build/build_report.sh` from the DVP folder after editing the markdown.
- [ ] **Before submission (manual):** insert the six FdS design sheets into the report Appendix (placeholders A–F are in place); crop the browser address bar off the seven screenshots; delete the commented "REFERENCE BLOCK" (the copied requirements) at the bottom of the report markdown; final proofread of Echo-edited prose.
- [ ] **Final app verification pass** — clean R session, run end-to-end, check tab navigation / hover tooltips / filter responsiveness / palette consistency, and confirm the five Tab 5 dataset links open. Exclude `.Rproj.user/` when zipping for submission.


## Resolved on 2026-05-21 (Tab 5 decisions — closed)

- **Tab 5 layout** → single `fluidPage` column, `<h3>`-headed sections inside one `.intro-narrative` div. No nested tabset, no two-column.
- **"How to use this app"** → **dropped.** The Intro tab + per-tab orienting paragraphs already guide interaction; a how-to on the last tab is redundant. (Echo's instinct, confirmed.)
- **Data-source listing format** → bulleted list (name + agency + link), matching the app's rhythm.
- **Dataset count** → **five (A–E)**, not six. Dataset F (ACS Borough Population) is unused by the running app, so listing it would mislead a marker who follows the URL.
- **AI-tool declaration** → **not in the app.** The FIT5147 brief (pages 1 and 8) requires it "at the end of your report". It belongs in `wanting_35507071_DVP_report.md`. Echo's preferred wording when it goes in the report: "co-work with Claude ai".
- **Logo / branding** → skip. The 🐾 emoji in the navbar title is sufficient (Echo confirmed after running the app).

## Resolved (report decisions — closed 2026-05-24)

- **Citation style** → APA 7th.
- **Section 2 organisation** → design-process narrative (2.1, walks the FdS sheets and the convergence/critique) + thematic justification (2.2–2.9). Rejected alternatives (pie/donut, heatmap, the old DVP1 palette, `ggplotly`) are critiqued as evidence of process, per the brief.
- **Design sheets** → six in the Appendix: Sheet 1 Brainstorm, Sheets 2–4 Layouts A/B/C, Sheet 5 Realisation, Sheet 6 the revised two-row Safety layout. Source: `/Users/ez_us/Documents/5147/DVP/DVP1/Wanting_35507071_FdS_0524.pdf` (7 pages incl. a title page).
- **Screenshots** → seven app captures in the DVP root (`Intro.png`, `trend.png`, `infrustracture1.png`, `infrustracture2.png`, `safety1.png`, `safety2.png`, `about.png`), embedded in Section 3.2 as Figures 1–5 (Infrastructure and Safety each show two states).
- **AI declaration** → drafted at the end of the report in the "co-work with Claude ai" framing.
- **Marker colour** → teal `#40B0A6` (NOT dark grey / `#1F2933`). The `app.R` comment, `notes_for_report.md`, and this file were corrected on 2026-05-24. The `#1F2933` references that remain (active-nav text, hover borders) are correct.

## How to resume — first message to the new chat

> Continue the Woof! NY DVP Part 2 work. Read
> `/Users/ez_us/Documents/5147/DVP/woof_ny_app/HANDOVER.md` first to load
> state. The five-tab app is **fully built** and the **DVP Part 2 report**
> at `/Users/ez_us/Documents/5147/DVP/wanting_35507071_DVP_report.md` has a
> **complete first draft** (Sections 1–4, bibliography, AI declaration), with
> a showcase PDF built via `report_build/build_report.sh`. I want to
> [DESCRIBE YOUR CHANGE — e.g. "revise Section 4", "tighten Section 2.5",
> "swap a screenshot", "re-run the PDF"].

After reading HANDOVER.md, also read the current report draft and `notes_for_report.md` (the design-decisions log behind Sections 2 and 3). To rebuild the PDF after any markdown edit, run `bash report_build/build_report.sh` from the DVP folder. Follow my working style: explain non-obvious changes before making them, keep my documents clear and consistent, and only include code/prose I can personally explain and defend.
