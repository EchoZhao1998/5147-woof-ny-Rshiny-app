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
- `HANDOVER.md` — this file. Update the "What's already built" and "Open items" sections after each tab.

DEP reference material (read-only; do not modify):
- `/Users/ez_us/Documents/5147/DVP/DEP_overview/DEP_DV_combined.R` — full wrangling + Phase-3 exploration script; existing ggplot designs to port.
- `/Users/ez_us/Documents/5147/DVP/DEP_overview/DEP2_ZHAOWANTING-35507071.pdf` — Echo's submitted DEP Part 2 report. Source of truth for: dataset URLs (Section 2.1), wrangling steps (Section 2.2), the Q3 rocket-palette decision the Safety tab inherits, and the AI-tool declaration that the About tab should mirror.
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

## What's already built

- [x] Project skeleton: `navbarPage()` with five `tabPanel()`s (Intro / Trends / Infrastructure / Safety / About).
- [x] Data loading: `master_filtered`, `bites_per_year_borough`, `dog_runs`. Bite-rate recompute applied. `bites_per_year_borough` now augmented at load with `yoy_pct`, `yoy_label`, `note` columns for the Trends rich tooltip.
- [x] Constants section: `borough_colours` (Okabe-Ito), `nyc_boroughs_map`, `borough_centroids`, three KPI values, `kpi_card()` helper, `tab2_apply_layout()` helper.
- [x] CSS section: peach navbar, orange hero heading, intro-narrative styling, KPI-card styling. **Typography fixed**: Futura-first cascade (`'Futura', 'Futura PT', 'Avenir Next', 'Avenir', 'Trebuchet MS', sans-serif`), body weight 400, `.intro-narrative` font-size 15px, `font_weight: 100` typo removed.
- [x] **Tab 1 (Introduction)** fully built: hero heading, two-column narrative + static ggplot borough reference map, three KPI cards across the bottom.
- [x] **Tab 2 (Trends)** fully built: hero "How have bite incidents changed?", checkbox borough filter on left, plotly line chart with rich tooltip (Year/Borough — bites, YoY %, COVID-year/Post-COVID-peak flag). COVID-19 yellow band 2019.5–2020.5 + "COVID-19 drop" and "Recovery peak" annotations on the chart layer. Native `plot_ly()` over `ggplotly()` because `annotate("rect", ...)` doesn't translate reliably. Interpretive narrative below the chart ("What this chart tells you" `<h3>` lead + two narrative paragraphs + three `<h4>` callouts: *Key takeaway*, *Important context*, *Continue exploring* with bulleted hand-off into Tabs 3 & 4). This multi-callout narrative shape is now the house style for tab reflections — Tabs 3 & 4 should follow the same structure.
- [x] **Tab 3 (Infrastructure)** fully built: hero "Where do dogs live, and where can they run?", `sidebarLayout(3/9)` mirroring Tab 2 — radio toggle on the left (*Dog density* default, *Gap index*), `leafletOutput("tab3_map", height = "520px")` on the right. **Two-part rendering**: `renderLeaflet` draws the base map once (CartoDB Positron tiles, `setView` to NYC, 91 `addCircleMarkers` in neutral dark grey with white halo, `popup = NAME + borough`); `observeEvent(input$tab3_metric, ...)` uses `leafletProxy` + `clearGroup("choropleth")` + `clearControls()` to swap the choropleth + legend without re-rendering markers or re-fetching tiles. **Palettes**: plasma fitted on `sqrt(dog_density)` for density (legend back-transforms with `labFormat = labelFormat(transform = function(x) x^2, digits = 0, big.mark = ",")` so ticks read in dogs/km²), viridis for `gap_index` (no transform — already in [0, 1]). **Polygon hover labels** (`tab3_polygon_labels`) pre-built once at startup as `lapply(...) → list(htmltools::HTML(...))` — ZIP, borough, "Dog density (2022)", off-leash runs, gap index. **Highlight on hover** = border thickening (`weight = 2`, `#1F2933`) only — no fill change, to preserve the colour encoding. House-style reflection block below the map: heading polished to "What this map tells us" on 2026-05-19, then 2 paragraphs → *Key takeaway* / *Important context* / *Continue exploring* with bulleted hand-off into Tabs 4 & 2. **Library additions**: `viridisLite`. **dplyr verb**: `dplyr::case_match()` (not `recode`) translates dog-run `BOROUGH` codes (`M/B/Q/X/R`) to full names — modern dplyr ≥ 1.1.0 idiom. **Acknowledged time-horizon mismatch**: `dog_density` in the rds is the 2022-only snapshot, `gap_index` was built on it, and `bite_rate` is cumulative — called out in the Important-context callout and in the tooltip label.
- [x] **Tab 4 (Safety)** fully built: hero "Does where you live shape how safe it is?". **Two-row layout** (Echo's restructure on 2026-05-19 replaced the initial 7/5 single-row design): **Row 1** is a 7/5 split — `leafletOutput("tab4_map", height = "500px")` on the left, a *map-specific* narrative block on the right (`<h3>` "What this map suggests?" + 3 short paragraphs + a `<h4>` "Before moving down" prompt). **Row 2** is a full-width `plotlyOutput("tab4_scatter", height = "500px")` — the scatter was moved out of row 1 because the 5-column variant overlapped dots in the high-income / low-bite cluster and hover targets were too small. **Map**: single `renderLeaflet` (no toggle, so no `leafletProxy` split), `pal_bites = colorNumeric(viridisLite::rocket(256, direction = -1))` so dark red = high bite rate, white hairline borders, `fillOpacity = 0.7`, `na.color = "#EEEEEE"` + `na.label = "No data"` on the legend, `tab4_polygon_labels` (ZIP / borough / bite rate / cumulative-2016–2023 qualifier / median income). **Scatter**: native `plot_ly`, `mode = "markers"`, `color = ~borough` with `colors = borough_colours`, 0.5px white halo around each marker (Cleveland overplotting fix), `tickformat = "$,d"` on x, `rangemode = "tozero"` on y, **legend rotated horizontal** above the chart (`orientation = "h", x = 0, y = 1.12`, top margin bumped to `t = 70`) because the full-width canvas left no room for a side legend. No trendline — confirmed design call, see *Open decisions* below. Bottom reflection block follows the house style: `<h3>` lead + paragraph (scatter-only now that the map has its own narrative beside it) + *Key takeaway* / *Important context* / *Continue exploring* with hand-off into Infrastructure and Trends. **`tab4_scatter_data`** is pre-built once at startup: `st_drop_geometry()` (so plotly does not serialise 182 MULTIPOLYGONs into the page JSON) + `filter(!is.na(median_income), !is.na(bite_rate))` (NA ZCTAs stay on the map as grey "No data"; they're dropped from the scatter to keep per-borough marker counts honest) + a pre-built `tooltip_text` string.

## What's left
- [ ] **Tab 5 (About)** — data sources listed with URLs (six datasets from DEP2 Section 2.1: Dog Licensing, Dog Bite, Dog Runs, ACS Income, TIGER/Line ZCTA boundaries, ACS Borough Population), how-to-use the app, student credit + AI-tool declaration mirroring DEP2 Section 5, GitHub repo link (DEP:`https://github.com/EchoZhao1998/NYC_dog_neighbour`, DVP:`https://github.com/EchoZhao1998/5147-woof-ny-Rshiny-app`).
- [ ] **Final verification pass** — clean R session, run end-to-end, check tab navigation / hover tooltips / filter responsiveness / palette consistency. Exclude `.Rproj.user/` when zipping for submission.


## Open decisions for next session

- **Tab 5 (About) layout** — single `fluidPage` column? Two-column (left: data sources list with URLs; right: how-to-use guide + credits)? `tabsetPanel` nested inside the tab? The simplest defensible default is a single column with `<h2>`-headed sections: *Data sources* → *How to use this app* → *Credits & acknowledgements* → *AI declaration*. Confirm before building.
> Notes: about the *AI declaration*. I think it only should in my DVP2 report? please ensure it in  `/Users/ez_us/Documents/5147/DVP/FIT5147_DataVisualisationProject S1 2026.pdf` if needed.
> *How to use this app*. If I put it at `about` page. I am concern about if it makes sence. because audience firstly in your `introduction` tab. And I think my narration on that page as well as following ones already guide them how to use. so I'd like think twice with you. 
- **Data-source listing format** — six datasets from DEP2 Section 2.1. Options: (a) bulleted list with bold dataset name + agency + URL; (b) HTML `<dl>` definition list; (c) styled table. Bulleted list is the lightest weight and matches the rest of the app's rhythm.
- **AI-tool declaration scope** — DEP2's declaration (Section 5) covers Claude as a tutoring aid plus ChatGPT/Grammarly for language refinement. Decide whether to port the declaration verbatim or paraphrase. Echo's call.
> if must declare here, I prefer write `co-work with Claude ai`
- **Logo / Woof! branding on the About tab** — none currently in the app. Optional: a single SVG paw mark beside the title block. Trade-off is an external asset in the submission zip vs. zero risk of a missing-file error. Default: skip unless Echo wants the visual lift.
> I think current version is acceptable. once I run the app. it show like emoji "🐾". You can have a better suggestion if I need design with third-party tools.

## How to resume — first message to the new chat

> Continue the Woof! NY DVP Part 2 build. Read
> `/Users/ez_us/Documents/5147/DVP/woof_ny_app/HANDOVER.md` first to load
> state — that file lists what's built, what's left, and the decisions
> we've already locked in. Today we tackle **Tab 5 (About)**.

After reading HANDOVER.md, your first action should be to inspect the current `app.R` so you know the styling and narrative voice already in use (Futura cascade, peach navbar, intro-narrative div, inclusive "us" voice on `<h3>`s). Then read DEP2_ZHAOWANTING-35507071.pdf Sections 2.1 and 5 — those are the source of truth for the data-source URLs and the AI declaration that Tab 5 mirrors. Propose the About-tab structure in prose (with the open decisions from HANDOVER) before writing any code, per my working style.
