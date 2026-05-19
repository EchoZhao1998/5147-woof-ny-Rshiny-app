# ============================================================================
#  WOOF! 🐾 NEW YORK — Interactive narrative visualisation
#  Dog Ownership, Safety & Infrastructure Across NYC Neighbourhoods (2016-2023)
#  FIT5147 Data Visualisation Project — Part 2
#  Author : Wanting (Echo) Zhao    Student ID : 35507071
#  Applied Session 12              Teaching Associate : Ashwini Narasimhan,
#                                                       Mohit Gupta
# ============================================================================


# ----------------------------------------------------------------------------
# 1. LIBRARIES
# ----------------------------------------------------------------------------
# Loaded in the order: core Shiny -> data handling -> visualisation.
# We deliberately do NOT load the full tidyverse — only the two packages we
# actually use (dplyr, readr) — so the marker's R session starts faster.

library(shiny)      # navbarPage(), tabPanel(), reactive(), render*(), etc.
library(sf)         # spatial data frame class — master_filtered.rds is sf
library(dplyr)      # mutate / select / filter (used by the bite_rate recompute)
library(readr)      # read_csv() for Dog_Runs.csv
library(leaflet)    # interactive choropleth + circle markers
library(plotly)     # interactive line chart (Trends) and scatter (Safety)
library(ggplot2)    # static borough reference map on the Introduction tab
library(viridisLite)# plasma() + viridis() palette vectors for the Tab 3
                    # leaflet choropleth. We use viridisLite rather than the
                    # full viridis package because we only need the palette
                    # generators - we are not using scale_fill_viridis_c().


# ----------------------------------------------------------------------------
# 2. DATA
# ----------------------------------------------------------------------------
# Files load ONCE at app start, outside server(). Shiny convention: code
# outside server() runs a single time per R session and the resulting
# objects are shared across every user that connects. Loading inside server()
# would re-read the rds on every visit — slower with no benefit because the
# data does not change between sessions.

# 2a. Master ZCTA-level frame (182 rows, sf) ---------------------------------
master_filtered <- readRDS("data/cleaned/master_filtered.rds")

# --- Bite-rate recompute ---
# Handover spec: bite_rate = total_bites / total_dogs * 1000, where
# total_dogs is the CUMULATIVE licensed-dog count across all extract years
# (2016, 2017, 2018, 2022, 2023). Label everywhere in the UI as
# "Bite rate (per 1,000 licensed dogs, cumulative 2016-2023)".
#
# Why we recompute here rather than trust the rds: the DEP wrangling script
# overwrote bite_rate near the end of Phase 3 with a 2022-only denominator.
# We drop that column and rebuild from the cumulative totals (total_bites,
# total_dogs) that are still in the file. Doing it in app.R — instead of
# re-saving the rds — keeps the formula sitting right next to the label in
# the UI, so the marker can verify the definition in three lines.

master_filtered <- master_filtered |>
  dplyr::select(-bite_rate) |>                          # drop 2022-only column
  dplyr::mutate(
    bite_rate = dplyr::if_else(
      total_dogs > 0,
      total_bites / total_dogs * 1000,
      NA_real_                                          # undefined when no dogs
    )
  )

# 2b. Borough-level annual bite counts (Trends tab) --------------------------
# Columns: year (numeric), borough (character), bite_count (integer).
bites_per_year_borough <- readRDS("data/cleaned/bites_per_year_borough.rds")

# --- Augment for the Trends-tab rich tooltip ---
# We pre-compute two derived columns at startup (NOT inside the reactive):
#   * yoy_pct   - percent change from the previous year, within borough.
#   * yoy_label - the same as a pre-formatted string ("+12%", "-27%", "-").
#   * note      - a short context flag for 2020 / 2022; empty otherwise.
#
# Rationale for doing this here:
#   1) bites_per_year_borough is static for the life of the R session, so
#      recomputing on every checkbox click would be wasted work.
#   2) Putting the formatting in dplyr (not in plotly) keeps the rendering
#      step trivial - plotly just reads the pre-built strings.
#
# group_by(borough) + arrange(year) is the standard lag() pattern from
# Week 8 Applied: lag() is positional, so we must guarantee per-borough
# row order BEFORE calling it.
bites_per_year_borough <- bites_per_year_borough |>
  dplyr::group_by(borough) |>
  dplyr::arrange(year, .by_group = TRUE) |>
  dplyr::mutate(
    yoy_pct = (bite_count - dplyr::lag(bite_count)) /
              dplyr::lag(bite_count) * 100,
    yoy_label = dplyr::if_else(
      is.na(yoy_pct),
      "—",                                        # em dash for 2016
      paste0(ifelse(yoy_pct >= 0, "+", ""),
             round(yoy_pct, 0), "%")
    ),
    note = dplyr::case_when(
      year == 2020 ~ "COVID year",
      year == 2022 ~ "Post-COVID peak",
      TRUE         ~ ""
    )
  ) |>
  dplyr::ungroup()

# 2c. Dog-run polygons (Infrastructure tab) ----------------------------------
# 91 off-leash run polygons in WKT form. We parse the_geom into an sf
# geometry column on load; we'll take centroids inside the Infrastructure
# tab when we draw the leaflet markers.
dog_runs <- readr::read_csv("data/raw/Dog_Runs.csv", show_col_types = FALSE) |>
  dplyr::filter(!is.na(the_geom)) |>
  sf::st_as_sf(wkt = "the_geom", crs = 4326) |>
  # Translate the NYC Parks Department single-letter borough codes to the full
  # names used by borough_colours and the rest of the app. The X-for-Bronx
  # quirk is a Parks Department convention (B was taken by Brooklyn).
  # case_match() is the modern (dplyr >= 1.1.0) replacement for recode(),
  # which is now "questioning" / soft-deprecated.
  dplyr::mutate(
    borough = dplyr::case_match(
      BOROUGH,
      "M" ~ "Manhattan",
      "B" ~ "Brooklyn",
      "Q" ~ "Queens",
      "X" ~ "Bronx",
      "R" ~ "Staten Island"
    )
  )


# ----------------------------------------------------------------------------
# 3. PROJECT-WIDE CONSTANTS & DERIVED OBJECTS
# ----------------------------------------------------------------------------

# 3a. Borough colour palette -------------------------------------------------
# Okabe & Ito (2008) Color Universal Design palette — remains distinguishable
# under deuteranopia, protanopia, and tritanopia. Replaces the original DEP
# palette, which paired Brooklyn pink-magenta with Bronx green (the textbook
# red-green problem for the most common form of colour-vision deficiency).
# Cited in Wong, Nature Methods 8, 441 (2011).
borough_colours <- c(
  "Manhattan"     = "#0072B2",   # blue
  "Brooklyn"      = "#CC79A7",   # reddish purple
  "Queens"        = "#E69F00",   # orange
  "Bronx"         = "#009E73",   # bluish green
  "Staten Island" = "#D55E00"    # vermillion
)

# 3b. Dissolved borough polygons + centroids (Introduction-tab map) ----------
# Computed ONCE at startup — never changes between sessions, so we keep it
# at module scope rather than inside renderPlot(). The lat nudges below are
# carried over from your DEP plot0_borough_reference: Staten Island and
# Bronx labels otherwise sit too close to their southern edges.
nyc_boroughs_map <- master_filtered |>
  dplyr::filter(!is.na(borough)) |>
  dplyr::group_by(borough) |>
  dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")

# st_centroid on lat/long data emits a "may not be accurate" warning — true
# in general, but at NYC scale the geometric error is sub-pixel for label
# placement, so we suppress it for a clean console.
borough_centroids <- suppressWarnings(sf::st_centroid(nyc_boroughs_map)) |>
  dplyr::mutate(
    lon = sf::st_coordinates(geometry)[, 1],
    lat = sf::st_coordinates(geometry)[, 2],
    lat = dplyr::case_when(
      borough == "Staten Island" ~ lat + 0.01,
      borough == "Bronx"         ~ lat + 0.01,
      TRUE                       ~ lat
    )
  )

# 3c. KPI values displayed on the Introduction tab ---------------------------
# Computed from data (not hard-coded) so a marker asking "where does this
# number come from?" can be answered by pointing at one expression.

kpi_n_zctas <- nrow(master_filtered)
# -> 182 ZCTAs in the filtered set.

kpi_pct_zero_runs <- paste0(
  round(mean(master_filtered$n_runs == 0) * 100, 1),
  "%"
)
# mean() of a logical vector = proportion that are TRUE; * 100 gives a
# percentage; round() to one decimal place. Expected to display as 64.8%.

# Which borough has the highest MEDIAN bite rate? Median (not mean) so a
# single outlier ZCTA cannot determine the winner.
kpi_top_bite_borough <- master_filtered |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(borough), !is.na(bite_rate)) |>
  dplyr::group_by(borough) |>
  dplyr::summarise(med_br = median(bite_rate), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(med_br)) |>
  dplyr::slice(1) |>
  dplyr::pull(borough)

# 3d. KPI card helper --------------------------------------------------------
# Six-line HTML component. Returns a styled <div> with a coloured top
# accent, a large value, and a smaller label. Styling lives in the CSS
# block in section 4.
kpi_card <- function(value, label, accent) {
  div(
    class = "kpi-card",
    style = paste0("border-top: 6px solid ", accent, ";"),
    div(class = "kpi-value", value),
    div(class = "kpi-label", label)
  )
}

# 3e. Tab 2 chart-layout helper ----------------------------------------------
# The Trends tab renders TWO plotly charts (simple vs rich tooltip) for the
# design-decision compare step. Their data, encoding, axes, COVID band,
# annotations and legend are identical - only the hover string differs.
#
# We pull the shared layout pipeline out as a helper so the two
# renderPlotly() bodies stay short and the difference between them is
# obviously just the tooltip.
#
# Implementation notes:
#   * shapes: a yellow rectangle spanning 2019.5 -> 2020.5 on the x-axis
#     and 0 -> 1 on yref="paper" (so the band always fills the full
#     vertical height, even after the user filters boroughs and the data
#     range changes). Layer "below" keeps it behind the data lines.
#   * annotations: two text labels (COVID-19 drop, Recovery peak) anchored
#     in paper coordinates near the top of the chart. showarrow = FALSE
#     because the rectangle itself does the pointing.
#   * yaxis$rangemode = "tozero" forces the y-axis to start at 0 (Munzner
#     ch. 6 - using a non-zero baseline on a line chart exaggerates change).
#   * config(displayModeBar = FALSE) hides the plotly toolbar; we want a
#     reading-the-story interaction, not a fiddle-with-the-chart one.
tab2_apply_layout <- function(p) {
  p |>
    layout(
      xaxis = list(
        title      = "Year",
        tickmode   = "linear",
        dtick      = 1,
        tickformat = "d"      # render years as 2016, not 2,016
      ),
      yaxis = list(
        title     = "Bite incidents (count)",
        rangemode = "tozero"
      ),
      shapes = list(
        list(
          type      = "rect",
          xref      = "x",
          yref      = "paper",
          x0        = 2019.5,
          x1        = 2020.5,
          y0        = 0,
          y1        = 1,
          fillcolor = "#FFFFCC",
          opacity   = 0.5,
          line      = list(width = 0),
          layer     = "below"
        )
      ),
      annotations = list(
        list(
          x = 2020, y = 0.97, xref = "x", yref = "paper",
          text = "COVID-19 drop", showarrow = FALSE,
          font = list(size = 12, color = "#525252")
        ),
        list(
          x = 2022, y = 0.97, xref = "x", yref = "paper",
          text = "Recovery peak", showarrow = FALSE,
          font = list(size = 12, color = "#525252")
        )
      ),
      legend = list(title = list(text = "Borough")),
      margin = list(t = 30, r = 20, b = 50, l = 60)
    ) |>
    config(displayModeBar = FALSE)
}


# 3f. Tab 3 (Infrastructure) helpers -----------------------------------------
# Three module-scope objects that the Tab 3 leaflet map depends on:
#   * dog_run_centroids - the lon/lat for the 91 circle markers
#   * pal_density       - colorNumeric closure: sqrt(dog_density) -> plasma
#   * pal_gap           - colorNumeric closure: gap_index         -> viridis
# Plus tab3_polygon_labels - one pre-built HTML hover label per ZCTA.
#
# Two design notes worth flagging in the report:
#
# (1) Two distinct hue families (plasma + viridis) instead of "darker vs
#     lighter green". Both palettes are perceptually uniform across their
#     domain and remain monotonic under deuteranopia (Crameri, Shephard &
#     Heron 2020, "The misuse of colour in science communication",
#     Nature Communications 11:5444). Using warm-for-density and cool-for-gap
#     gives an immediate read on which view is active without consulting
#     the legend - the same channel-separation idea Bertin formalised.
#
# (2) sqrt transform on dog_density only. Density is right-skewed (a few
#     dense Manhattan ZCTAs vs many sparse outer-borough ones). A linear
#     mapping burns most of the colour ramp on the upper tail. sqrt is the
#     conservative monotonic transform (Cleveland 1985; Munzner ch.6 on
#     non-linear scales for skewed quantitative attributes). The legend
#     back-transforms with labelFormat(transform = function(x) x^2) so the
#     printed tick labels read in dogs/km^2, not in sqrt units. gap_index
#     is not transformed because it is constructed as a product of two
#     min-max-rescaled variables and already sits in [0, 1].
#
# Note on dog_density's time horizon: the column in master_filtered.rds is
# the 2022-only snapshot (dogs_2022 / area_km^2) - see DEP wrangling
# DEP_DV_combined.R line 853. gap_index was constructed on top of that,
# so the two metrics are internally consistent. This differs from
# bite_rate, which is the cumulative 2016-2023 measure. The mismatch is
# called out explicitly in the Tab 3 "Important context" callout below.

# Centroid lat/long for each of the 91 dog-run polygons.
#
# Implementation note: we extract coordinates with sf::st_coordinates() on
# the sf OBJECT - not on a named geometry column inside mutate() - because
# dog_runs's active geometry column is named "the_geom" (carried over from
# the CSV's WKT column during st_as_sf(wkt = "the_geom")), whereas
# master_filtered's is named "geometry" (set explicitly by the DEP
# wrangling's summarise(geometry = st_union(geometry))). st_coordinates()
# on an sf object always uses the active geometry regardless of name, so
# this stays robust to the asymmetry without us having to rename columns.
#
# st_centroid on unprojected lat/long emits a "may not be accurate"
# warning - true in general, but at the scale we render (city-wide
# leaflet at zoom 10) the geometric error is well below one pixel. Same
# justification as borough_centroids in 3b.
dog_run_centroids <- suppressWarnings(sf::st_centroid(dog_runs))
dog_run_coords    <- sf::st_coordinates(dog_run_centroids)
dog_run_centroids$lon <- dog_run_coords[, 1]
dog_run_centroids$lat <- dog_run_coords[, 2]

# Plasma palette closure. We pass sqrt(dog_density) as the DOMAIN, which
# fits the palette to the sqrt-transformed range. We then call
# pal_density(sqrt(dog_density)) at render time. na.color = light grey
# so any ZCTA missing a density value reads as "no data" rather than
# vanishing.
pal_density <- leaflet::colorNumeric(
  palette  = viridisLite::plasma(256),
  domain   = sqrt(master_filtered$dog_density),
  na.color = "#EEEEEE"
)

# Viridis palette closure. Untransformed; gap_index already sits in [0, 1].
pal_gap <- leaflet::colorNumeric(
  palette  = viridisLite::viridis(256),
  domain   = master_filtered$gap_index,
  na.color = "#EEEEEE"
)

# Pre-built per-ZCTA hover labels. Built ONCE at startup because
# master_filtered is static - identical split-phase reasoning to the YoY
# string we pre-compute for the Trends tooltip (see section 2b).
#
# leaflet's `label` argument on addPolygons accepts either a character
# vector OR a list of htmltools::HTML objects. We use the latter because
# we want <br>, <strong>, <sup> to render rather than show as literal
# tag text. lapply over row indices is the standard pattern.
tab3_polygon_labels <- lapply(seq_len(nrow(master_filtered)), function(i) {
  r <- master_filtered[i, ]
  htmltools::HTML(paste0(
    "<strong>ZIP ", r$zipcode, "</strong><br>",
    "Borough: ", r$borough, "<br>",
    "Dog density (2022): ",
      ifelse(is.na(r$dog_density), "n/a",
             paste0(format(round(r$dog_density), big.mark = ","),
                    " dogs/km<sup>2</sup>")),
    "<br>",
    "Off-leash runs: ", r$n_runs, "<br>",
    "Gap index: ",
      ifelse(is.na(r$gap_index), "n/a", format(round(r$gap_index, 2), nsmall = 2))
  ))
})


# 3g. Tab 4 (Safety) helpers -------------------------------------------------
# Three module-scope objects for the Safety tab:
#   * pal_bites           - colorNumeric closure: bite_rate -> rocket reversed
#   * tab4_polygon_labels - one pre-built HTML hover label per ZCTA
#   * tab4_scatter_data   - non-spatial data frame for the plotly scatter
# All static for the life of the R session, so we build them once at startup
# (same split-phase reasoning as bites_per_year_borough's YoY columns in 2b
# and tab3_polygon_labels in 3f).

# Rocket palette closure for bite_rate.
#
# Why rocket: it is the warm-toned member of the viridis family
# (viridisLite::rocket goes from light cream through magenta to deep red).
# It carries the same perceptual-uniformity guarantee as plasma / viridis
# (Crameri, Shephard & Heron 2020) but reads as alarming rather than
# neutral - the right tone for a "high values are bad" variable like
# bite incidents per dog.
#
# direction = -1 reverses the palette vector BEFORE colorNumeric sees it,
# so HIGH bite rate maps to the DARK red end and LOW bite rate maps to the
# cream end. Without this, dark = safe, which is the opposite of what a
# reader's visual instinct expects on a safety map.
#
# We deliberately do NOT sqrt-transform bite_rate. Unlike dog_density
# (heavily right-skewed - a few Manhattan ZCTAs dominate), bite_rate is
# bounded by both a meaningful zero and the per-1,000 normalisation, so
# its distribution sits closer to linear. The legend therefore reads in
# native units (bites per 1,000 dogs) with no back-transform.
#
# na.color = light grey for ZCTAs with NA bite_rate (total_dogs == 0, so
# the rate is undefined - see the bite_rate recompute in section 2a).
# Same convention as pal_density / pal_gap in 3f.
pal_bites <- leaflet::colorNumeric(
  palette  = viridisLite::rocket(256, direction = -1),
  domain   = master_filtered$bite_rate,
  na.color = "#EEEEEE"
)

# Pre-built per-ZCTA hover labels for the Safety choropleth.
# Same lapply(seq_len(nrow(...))) -> list(htmltools::HTML(...)) pattern as
# tab3_polygon_labels; leaflet's `label` argument accepts a list of HTML
# objects so <br>, <strong>, <small> render rather than appear as literal
# tags.
#
# Four fields per label: ZIP, borough, bite_rate (with the cumulative
# 2016-2023 qualifier so the unit is unambiguous even when the legend is
# off-screen), and median household income (with a "$" prefix and
# big.mark = "," so a reader can pattern-match against US dollar values
# they would see on a paycheque or census report).
tab4_polygon_labels <- lapply(seq_len(nrow(master_filtered)), function(i) {
  r <- master_filtered[i, ]
  htmltools::HTML(paste0(
    "<strong>ZIP ", r$zipcode, "</strong><br>",
    "Borough: ", r$borough, "<br>",
    "Bite rate: ",
      ifelse(is.na(r$bite_rate), "n/a",
             paste0(format(round(r$bite_rate, 1), nsmall = 1),
                    " per 1,000 dogs")),
    "<br>",
    "<small>(cumulative 2016&ndash;2023)</small><br>",
    "Median income: ",
      ifelse(is.na(r$median_income), "n/a",
             paste0("$", format(round(r$median_income), big.mark = ",")))
  ))
})

# Non-spatial data frame for the income x bite_rate scatter.
#
# Two operations matter here:
#
# (1) st_drop_geometry(): plot_ly does not need the polygon geometries to
#     draw scatter points - only the attribute columns. Without this drop,
#     plotly would serialise all 182 MULTIPOLYGON features into the JSON
#     it ships to the browser, ballooning the page weight for no visual
#     benefit. Dropping geometry first is the standard sf-to-plot_ly idiom.
#
# (2) filter(!is.na(median_income), !is.na(bite_rate)): a scatter point at
#     (NA, y) or (x, NA) renders nothing but still appears in the legend
#     count - dropping these rows up front keeps the per-borough marker
#     counts honest. ZCTAs with NA values are still visible on the LEFT
#     view (the choropleth shows them as the na.color grey), so removing
#     them from the scatter does not hide them from the reader; it just
#     puts them in the right view.
#
# tooltip_text is pre-built so plot_ly's hovertemplate can read it
# verbatim - same pattern as the Trends-tab tooltip in section 6.
tab4_scatter_data <- master_filtered |>
  sf::st_drop_geometry() |>
  dplyr::filter(!is.na(median_income), !is.na(bite_rate)) |>
  dplyr::mutate(
    tooltip_text = paste0(
      "<b>ZIP ", zipcode, "</b><br>",
      "Borough: ", borough, "<br>",
      "Median income: $", format(round(median_income), big.mark = ","), "<br>",
      "Bite rate: ", format(round(bite_rate, 1), nsmall = 1),
      " per 1,000 dogs"
    )
  )


# ----------------------------------------------------------------------------
# 4. CUSTOM STYLING (CSS injected into <head>)
# ----------------------------------------------------------------------------
# Brand peach for the navbar, orange hero heading on Tab 1, and the KPI
# card styling for the helper in section 3d. Kept inline so every styled
# element is visible in this single file.
woof_css <- "
body {
  /* Futura first (Echo's Mac default) -> Avenir Next as the closest macOS
     fallback -> Trebuchet MS as the only widely-installed geometric-ish sans
     on Windows -> generic sans-serif as final safety net. */
  font-family: 'Futura', 'Futura PT', 'Avenir Next', 'Avenir',
               'Trebuchet MS', sans-serif;
  /* 400 = Futura Book weight; reads cleanly on screen. <strong>/<b> default
     to 700 in every browser, so bold tags keep their emphasis. */
  font-weight: 400;
}
.navbar.navbar-default {
  background-color: #FBE3C5 !important;
  border-color: #FBE3C5 !important;
}
.navbar-default .navbar-brand,
.navbar-default .navbar-nav > li > a {
  color: #1F2933 !important;
  font-weight: 500;
}
.navbar-default .navbar-nav > .active > a,
.navbar-default .navbar-nav > .active > a:focus,
.navbar-default .navbar-nav > .active > a:hover {
  background-color: #F5C896 !important;
  color: #1F2933 !important;
}
.intro-heading {
  font-size: 3rem;
  font-weight: 700;
  color: #E69F00;
  margin: 1.5rem 0 1rem 0;
  text-align: center;
}
.intro-narrative {
  /* 15px (not 14) because Futura has a smaller x-height than Segoe UI, so
     equivalent visual weight needs a slightly larger size. */
  font-size: 15px;
  /* font-weight inherits 400 from body. Removed the previous
     `font_weight: 100` (typo: underscore not hyphen, browsers ignored it). */
  line-height: 1.6;
  color: #1F2933;
  padding: 0.5rem 1rem;
}
.intro-narrative ul { padding-left: 1.2rem; }
.intro-narrative li { margin-bottom: 0.35rem; }
.kpi-card {
  background: #FAFAFA;
  padding: 1.25rem 1rem;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-align: center;
  margin: 0.5rem 0;
}
.kpi-value {
  font-size: 2.1rem;
  font-weight: 700;
  color: #E69F00;
  line-height: 1.1;
}
.kpi-label {
  font-size: 1.2rem;
  color: #525252;
  margin-top: 0.4rem;
}
"


# ============================================================================
# 5. UI
# ============================================================================

ui <- navbarPage(
  title = "Woof! 🐾 New York",

  # Inject CSS into <head>. tags$style() writes a literal <style>...</style>
  # block; HTML() prevents Shiny from escaping the CSS.
  header = tags$head(tags$style(HTML(woof_css))),

  # -------------------------------------------------------------------------
  # Tab 1: Introduction
  # -------------------------------------------------------------------------
  tabPanel(
    title = "Introduction",
    fluidPage(

      # Hero heading
      div(class = "intro-heading", "Are you a dog owner?"),

      # Two-column body: narrative left, borough reference map right
      fluidRow(
        column(
          width = 6,
          div(
            class = "intro-narrative",
            p(strong("Woof! New York"), " is an interactive narrative ",
              "visualisation of dog ownership, off-leash infrastructure, ",
              "and bite safety across the five boroughs of New York City ",
              "(2016-2023)."),
            p("It is designed for ", strong("NYC residents who already own ",
              "a dog — or are thinking about getting one"), ". ",
              "Use the tabs above to explore how dog life changes across New York City"),
            tags$ul(
              tags$li(strong("Trends"), " — how bite incidents shifted across ",
                      "the years, including the 2020 COVID dip."),
              tags$li(strong("Infrastructure"), " — where off-leash parks ",
                      "are, and where the gap between dogs and parks is widest."),
              tags$li(strong("Safety"), " — how bite rate relates to ",
                      "neighbourhood income."),
              tags$li(strong("About"), " — data sources and credits.")
            ),
            p(em("Tip:"), " hover over any map polygon or chart point for ",
              "details. The same colour always means the same borough.")
          )
        ),
        column(
          width = 6,
          plotOutput("intro_borough_map", height = "420px")
        )
      ),

      # KPI cards row
      br(),
      fluidRow(
        column(width = 4, kpi_card(
          value  = kpi_n_zctas,
          label  = "NYC ZCTAs analysed",
          accent = "#1F2933"
        )),
        column(width = 4, kpi_card(
          value  = kpi_pct_zero_runs,
          label  = "have zero off-leash runs",
          accent = "#1F2933"
        )),
        column(width = 4, kpi_card(
          value  = kpi_top_bite_borough,
          label  = "has the highest median bite rate",
          accent = "#1F2933"
        ))
      ),
      br()
    )
  ),

  # -------------------------------------------------------------------------
  # Tab 2: Trends
  # -------------------------------------------------------------------------
  # Story: how bite incidents shifted across 2016-2023, especially the 2020
  # COVID dip and the 2022 recovery peak. One full-width line chart per
  # borough; viewer can isolate boroughs with the left-side checkboxes.
  # Tooltip carries pre-built YoY % + a 2020/2022 context flag (rich
  # variant; the simpler variant was prototyped side-by-side and removed
  # after the design comparison - see notes_for_report.md Tab 2 section).
  tabPanel(
    title = "Trends",
    fluidPage(

      # Hero heading (same class as Tab 1 -> consistent narrative voice).
      div(class = "intro-heading", "How have bite incidents changed?"),

      # Orienting sentence above the chart so a reader knows what they're
      # looking at without scrolling to read the narrative.
      div(
        class = "intro-narrative",
        p("Annual reported dog-bite incidents by borough, 2016-2023. ",
          "Use the checkboxes on the left to isolate boroughs and compare ",
          "the COVID-era dip with the post-2022 recovery.")
      ),

      sidebarLayout(
        sidebarPanel(
          width = 3,
          checkboxGroupInput(
            inputId  = "tab2_boroughs",
            label    = "Show boroughs:",
            choices  = names(borough_colours),
            # All five pre-checked -> the default view answers the headline
            # question without the user needing to click anything (Cairo,
            # 2016: "the default state of an interactive view should already
            # tell a story").
            selected = names(borough_colours)
          ),
          tags$small(
            style = "color: #525252;",
            "Untick a borough to remove its line."
          )
        ),
        mainPanel(
          width = 9,
          plotlyOutput("tab2_chart", height = "440px")
        )
      ),

      # ---- Interpretive note ------------------------------------------
      # Sits BELOW the chart, mirroring the Setup -> Visual -> Reflection
      # pattern from Segel & Heer (2010, "Narrative Visualization"). The
      # orienting sentence above the chart frames what the reader is
      # about to see; this block summarises what they should take away.
      div(
        class = "intro-narrative",
        tags$h3(
          "What this chart tells us",
          style = "margin-top: 1rem; margin-bottom: 0.5rem;"
        ),

        p(
          "Some boroughs report far more bite incidents than others.",
          "Queens records the highest number of reported bite incidents almost every year — ",
          "even though it is not the borough with the most licensed dogs. ",
          "This suggests that bite incidents are shaped by more than population alone. ",
          "Local parks, crowding, and daily routines may all affect safety."
        ),

        p(
          "One pattern stands out in 2020. Every borough experiences ",
          "a sharp decline during the COVID-19 period, when lockdowns reduced outdoor ",
          "interaction between people and dogs, and many minor incidents were likely ",
          "underreported. By 2022 and 2023, most boroughs return close to — or even exceed — ",
          "pre-pandemic levels."
        ),

        br(),

        tags$h4("Key takeaway"),
        p(
          "Dog safety is not simply about ‘more dogs equals more bites.’ ",
          "The data points toward broader urban and social factors that influence ",
          "how safely dogs and people share space in the city."
        ),

        br(),

        tags$h4("Important context"),
        p(
          "These figures represent absolute incident counts, not bite rates. ",
          "NYC licensing data is unavailable for 2019–2021, so a standardised ",
          "rate per licensed dog cannot be calculated for those years."
        ),

        br(),

        tags$h4("Continue exploring"),
        p(
          "This dashboard is designed to help residents better understand ",
          "how dog-friendly conditions vary across NYC neighbourhoods."
        ),

        tags$ul(
          tags$li(
            strong("Infrastructure"),
            " explores where off-leash access is limited relative to local dog populations."
          ),
          tags$li(
            strong("Safety"),
            " examines how bite rates relate to neighbourhood income and inequality."
          )
        ),

        p(
          "Together, these views reveal how infrastructure access, density, ",
          "and socio-economic conditions may shape everyday experiences for ",
          "dog owners across the city."
        )
      ),
      br()
    )
  ),

  # -------------------------------------------------------------------------
  # Tab 3: Infrastructure
  # -------------------------------------------------------------------------
  # Story: where do dogs live, and where can they actually run? One leaflet
  # map shows two encoded variables - dog density (plasma + sqrt) and the
  # gap index (viridis) - toggled with a radio button. The 91 dog-run
  # centroids overlay both views so the gap is visually grounded: you can
  # SEE the ZCTAs with no nearby marker.
  #
  # Layout mirrors Tab 2 (sidebarLayout 3/9) so the app's interactive
  # grammar reads as one consistent pattern: controls left, visual right.
  tabPanel(
    title = "Infrastructure",
    fluidPage(

      # Hero question - same .intro-heading class as Tabs 1 & 2.
      div(class = "intro-heading", "Where do dogs live, and where can they run?"),

      # Orienting paragraph: 1-2 sentences that tell the reader what they're
      # looking at before scrolling further. Same convention as Tab 2.
      div(
        class = "intro-narrative",

        p(
          "Some neighbourhoods have dense dog populations and multiple official off-leash runs, ",
          "while others have growing dog communities but very limited public space designed for them."
        ),

        p(
          "Use the toggle on the left to switch between two perspectives: ",
          strong("dog density"),
          " (licensed dogs per square kilometre) and ",
          strong("gap index"),
          " (where dogs outnumber nearby off-leash spaces)."
        ),

        p(
          "Each point on the map represents an official NYC off-leash dog run. "),
        p(
          "Click the green dot to see details of each park",
          br(),
          "Hover over a ZIP code to explore local conditions and compare neighbourhood patterns across the city."
        )
      ),

      sidebarLayout(
        sidebarPanel(
          width = 3,
          radioButtons(
            inputId  = "tab3_metric",
            label    = "Show on the map:",
            choices  = c(
              "Dog density (per km²)" = "density",
              "Gap index"             = "gap"
            ),
            # Default to density so the headline view is "where the dogs
            # are" - the natural opening sentence of the story. Switching
            # to gap_index is the reveal.
            selected = "density"
          ),
          tags$small(
            style = "color: #525252;",
            tags$strong("Gap index:"),
            br(),
            "High = many dogs, few off-leash spaces. ",
            br(),
            "Built from licensed dogs (2022) and the count of official runs."
          )
        ),
        mainPanel(
          width = 9,
          leafletOutput("tab3_map", height = "520px")
        )
      ),

      # ---- Interpretive reflection (house style, locked decision #9) -----
      # Same shape as Tab 2's below-chart block: <h3> lead, two narrative
      # paragraphs, three <h4> callouts (Key takeaway / Important context /
      # Continue exploring) with bulleted hand-off into the next tab(s).
      div(
        class = "intro-narrative",
        tags$h3(
          "What this map tells us",
          style = "margin-top: 1rem; margin-bottom: 0.5rem;"
        ),

        p(
          "Manhattan and parts of north-west Brooklyn carry the highest ",
          "dog density in the city - and these are also the areas best ",
          "served by official off-leash runs. Move outward into Queens, ",
          "the Bronx, and Staten Island, Dog runs become much harder to find.",
          "Most of the city's ZIP codes have ",
          strong("no off-leash run at all"), "."
        ),

        p(
          "Switching to the gap index changes the story from population to access. ",
          "Some neighbourhoods with large dog communities still have very limited off-leash space nearby. ",
          "The brightest areas on the map highlight places where dogs may be competing for fewer public spaces to exercise and socialise."
        ),

        br(),

        tags$h4("Key takeaway"),
        p(
          "More dogs does not always mean more dog-friendly space. Some neighbourhoods have growing dog communities but limited room for exercise, play, and off-leash activity. Exploring these patterns can help residents better understand how daily dog life may differ across NYC."
        ),

        br(),

        tags$h4("Important context"),
        p(
          "Dog density is calculated using licensed dogs in 2022 (per square kilometre), ",
          "and the gap index is built from the same snapshot year. The infrastructure ",
          "dataset only includes officially designated off-leash runs, meaning informal ",
          "community spaces or parks with limited off-leash hours are not captured here."
        ),

        br(),

        tags$h4("Continue exploring"),
        p(
          "The next sections connect infrastructure access to broader safety patterns ",
          "across NYC neighbourhoods."
        ),

        tags$ul(
          tags$li(
            strong("Safety"),
            " explores whether neighbourhoods with limited infrastructure also ",
            "experience higher bite rates, and how income relates to those outcomes."
          ),
          tags$li(
            strong("Trends"),
            " revisits the long-term 2016–2023 bite patterns with this infrastructure ",
            "map in mind."
          )
        )
      ),
      br()
    )
  ),

  # -------------------------------------------------------------------------
  # Tab 4: Safety
  # -------------------------------------------------------------------------
  # Story: how bite rate relates to neighbourhood income. Two coordinated
  # views (no explicit crosstalk - the reader does the linking by eye, same
  # convention as Munzner ch.11 "multiple views without selection linking"):
  #   * Left 7/12 - leaflet choropleth of bite_rate (rocket reversed).
  #   * Right 5/12 - plotly scatter of median_income vs bite_rate, coloured
  #     by borough.
  #
  # Layout: Bootstrap's 12-column grid offers 7/5 (~58/42) and 8/4
  # (~67/33). We pick 7/5 because it is the closer approximation to the
  # HANDOVER's 60/40 spec, and 8/4 squeezes the scatter enough that the
  # $-formatted x-axis ticks would crash into the borough legend.
  #
  # No sidebarLayout: Tab 4 has no filter / toggle input - the scatter
  # already encodes borough via colour, and the map shows all ZCTAs at
  # once. A sidebarLayout would leave an empty sidebar column.
  tabPanel(
    title = "Safety",
    fluidPage(

      # Hero heading - same .intro-heading class as Tabs 1-3.
      div(class = "intro-heading", "Does where you live shape how safe it is?"),

      # Orienting paragraph(s): what the two views are, before the reader
      # scrolls into them. Same Setup -> Visual -> Reflection scaffolding
      # as Tabs 2 & 3.
      div(
        class = "intro-narrative",
        p(
          "Bite incidents do not happen uniformly across the city. ",
          "The map below shades each ZIP code by its ",
          strong("bite rate per 1,000 licensed dogs (cumulative 2016–2023)"),
          " - darker red means a higher reported rate. The scatter on the right ",
          "plots the same rate against ",
          strong("median household income"),
          " for that ZIP code, with each dot coloured by borough."
        ),
        p(
          "Hover any ZIP code on the map, or any point on the scatter, ",
          "to see the underlying numbers."
        )
      ),

      # -------------------------------------------------------------------
      # Row 1: Spatial overview + guided interpretation
      # -------------------------------------------------------------------
      fluidRow(

        # LEFT — map
        column(
          width = 7,
          leafletOutput("tab4_map", height = "500px")
        ),

        # RIGHT — short guided narrative
        column(
          width = 5,

          div(
            class = "intro-narrative",

            tags$h3(
              "What this map tell us?",
              style = "margin-top: 0;"
            ),

            p(
              "The highest bite rates do not concentrate in Manhattan, ",
              "even though Manhattan has the city's highest dog density. ",
              "Instead, darker areas appear in parts of the Bronx, central Brooklyn, ",
              "and southern Queens."
            ),

            p(
              "Several of these neighbourhoods also appeared earlier in the ",
              strong("Infrastructure"),
              " tab as places with limited off-leash access."
            ),

            p(
              "This suggests that safety outcomes may relate not only to dog ownership itself, ",
              "but also to how public space, infrastructure access, and neighbourhood conditions interact."
            ),

            br(),

            tags$h4("Before moving down"),
            p(
              "Use the scatter plot below to explore whether income patterns help explain ",
              "some of these spatial differences across NYC ZIP codes."
            )
          )
        )
      ),

      br(),

      # -------------------------------------------------------------------
      # Row 2: Full-width scatter plot
      # -------------------------------------------------------------------
      fluidRow(
        column(
          width = 12,
          plotlyOutput("tab4_scatter", height = "500px")
        )
      ),

      # ---- Interpretive reflection (house style, locked decision #9) -----
      # Same shape as Tabs 2 & 3: <h3> lead, two narrative paragraphs, three
      # <h4> callouts (Key takeaway / Important context / Continue exploring)
      # with bulleted hand-off into the next relevant tab(s).
      div(
        class = "intro-narrative",
        tags$h3(
          "What this view tells us?",
          style = "margin-top: 1rem; margin-bottom: 0.5rem;"
        ),

        p(
          "The scatter plot adds another layer to the story by comparing bite rate with neighbourhood income. ",
          "Some lower-income ZIP codes appear higher on the bite-rate axis, while many higher-income areas cluster lower. ",
          "However, the relationship is not consistent across the city. Boroughs overlap heavily, and many neighbourhoods ",
          "do not follow the overall trend. This suggests that income alone cannot explain dog safety outcomes."
        ),

        br(),

        tags$h4("Key takeaway"),
        p(
          "Dog safety patterns are connected to many neighbourhood conditions at once — ",
          "including infrastructure access, housing density, public space, and community routines. ",
          "Income may relate to some of these differences, but it does not determine whether a neighbourhood ",
          "is ‘good’ or ‘bad’ for dogs. The map instead highlights how uneven urban conditions can shape ",
          "everyday experiences for dog owners across NYC."
        ),

        br(),

        tags$h4("Important context"),
        p(
          "The bite rate combines reported incidents from 2016–2023, ",
          "while median household income is a single snapshot from the ",
          "American Community Survey - the two metrics cover different time ",
          "horizons. Reported bites also depend on local reporting culture: ",
          "neighbourhoods with stronger ties to 311 may show higher rates ",
          "without being more dangerous in absolute terms. And correlation ",
          "is not causation - income does not cause bites. Both probably ",
          "reflect deeper conditions such as housing density, access to ",
          "veterinary care, and the breed mix of locally licensed dogs."
        ),

        br(),

        tags$h4("Continue exploring"),
        p(
          "Cross-reference what you see here against the earlier views ",
          "to build a fuller picture of any neighbourhood you care about."
        ),

        tags$ul(
          tags$li(
            strong("Infrastructure"),
            " - check whether the high-bite-rate ZIP codes on this map also ",
            "appear bright on the gap-index view. Where they overlap, ",
            "limited off-leash space and elevated bite rates reinforce each other."
          ),
          tags$li(
            strong("Trends"),
            " - the 2022 post-COVID recovery peak is not distributed evenly ",
            "across boroughs; this map suggests which neighbourhoods are ",
            "driving that recovery."
          )
        )
      ),
      br()
    )
  ),

  # -------------------------------------------------------------------------
  # Tab 5: About
  # -------------------------------------------------------------------------
  # Single-column credits page. No sidebar, no charts - this tab is short-form
  # content (project summary, data sources, credits, source code, footer).
  # A sidebarLayout would leave half the canvas empty.
  #
  # Voice: same .intro-heading and .intro-narrative classes as Tabs 1-4, but
  # the reflection-block pattern (<h3> "What this map tells us" + <h4>
  # callouts) is intentionally NOT used here - that scaffolding carries an
  # interpretive story off a chart, and this tab has no chart. Plain <h3>
  # section headings inside the .intro-narrative wrapper keep the typography
  # consistent without cargo-culting the reflection convention.
  #
  # External links use target = "_blank" so a click opens in a new browser
  # tab (the user does not lose their place in the app), with
  # rel = "noopener noreferrer" to prevent tabnabbing and strip the Referer
  # header. Standard external-link hardening.
  #
  # Datasets listed: A-E only. Dataset F (ACS Borough Population) appears in
  # DEP2 Section 2.1 but is NOT read by the running Shiny app - it was used
  # in DEP for borough-level per-capita ownership trends, which did not make
  # it into the final five-tab implementation. Listing it here would mislead
  # a marker who follows the URL.
  tabPanel(
    title = "About",
    fluidPage(

      # Hero heading - same .intro-heading class as Tabs 1-4 (peach navbar
      # locked decision #8, consistent typography across all five tabs).
      div(class = "intro-heading", "About this project"),

      div(
        class = "intro-narrative",

        # ----- Opening paragraph -----
        # One short paragraph: what Woof! NY is, who it's for, what data
        # window, and its origin as a DEP. Mirrors the framing from the
        # Introduction tab without duplicating its narrative verbatim.
        p(
          strong("Woof! New York"), " is an interactive narrative ",
          "visualisation of dog ownership, off-leash infrastructure, ",
          "and bite safety across the five boroughs of New York City ",
          "(2016–2023). It is designed for NYC residents who already ",
          "own a dog — or are considering getting one — and ",
          "for anyone in their household curious about how dog life ",
          "varies across the city."
        ),
        p(
          "The project began as a Data Exploration Project (DEP) for ",
          "FIT5147 in Semester 1, 2026, and was rebuilt as this five-tab ",
          "R Shiny app for the Data Visualisation Project."
        ),

        # ----- Data sources -----
        # Bulleted list (not <dl> or a table) to match the rhythm of the
        # bulleted list at the bottom of Tab 1's narrative. Dataset name +
        # agency in parentheses, then a one-sentence description, then the
        # link. The dataset letters (A-E) match DEP2 Section 2.1 so a
        # marker cross-referencing the report and the app sees the same
        # labels.
        tags$h3("Data sources"),
        p(
          "All five datasets are openly accessible and were retrieved ",
          "between March and May 2026."
        ),
        tags$ul(
          tags$li(
            strong("Dataset — NYC Dog Licensing Dataset"),
            " (NYC Department of Health and Mental Hygiene). Annual ",
            "licence-transaction extracts for 2016, 2017, 2018, 2022, ",
            "and 2023. ",
            tags$a(
              href   = "https://data.cityofnewyork.us/Health/NYC-Dog-Licensing-Dataset/nu7n-tubp",
              target = "_blank",
              rel    = "noopener noreferrer",
              "data.cityofnewyork.us"
            )
          ),
          tags$li(
            strong("Dataset — DOHMH Dog Bite Data"),
            " (NYC Department of Health and Mental Hygiene). ",
            "Incident-level reports of dog bites across 2016–2023. ",
            tags$a(
              href   = "https://data.cityofnewyork.us/Health/DOHMH-Dog-Bite-Data/rsgh-akpg",
              target = "_blank",
              rel    = "noopener noreferrer",
              "data.cityofnewyork.us"
            )
          ),
          tags$li(
            strong("Dataset — NYC Dog Runs and Off-Leash Areas"),
            " (NYC Parks Department). 91 official off-leash run polygons ",
            "in WKT geometry. ",
            tags$a(
              href   = "https://data.cityofnewyork.us/Recreation/Dog-Runs/hxx3-bwgv/about_data",
              target = "_blank",
              rel    = "noopener noreferrer",
              "catalog.data.gov"
            )
          ),
          tags$li(
            strong("Dataset — Median Household Income by ZCTA"),
            " (US Census Bureau, American Community Survey 5-year ",
            "estimates, 2018–2022). Accessed programmatically via the ",
            "R ", tags$code("tidycensus"), " package. ",
            tags$a(
              href   = "https://www.census.gov/programs-surveys/acs",
              target = "_blank",
              rel    = "noopener noreferrer",
              "census.gov/programs-surveys/acs"
            )
          ),
          tags$li(
            strong("Dataset — TIGER/Line ZCTA Boundaries"),
            " (US Census Bureau, 2020). 182 NYC ZCTA polygons used as the ",
            "spatial framework for every choropleth in the app. Accessed ",
            "via the R ", tags$code("tigris"), " package. ",
            tags$a(
              href   = "https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html",
              target = "_blank",
              rel    = "noopener noreferrer",
              "census.gov/geographies"
            )
          )
        ),

        # ----- Credits -----
        # Two short paragraphs. The first carries author, student ID, unit,
        # institution, and teaching associates - the same identity block
        # that appears at the top of app.R but presented in a reader-
        # friendly sentence. The second names the R packages, mirroring the
        # "Tools used:" footer line that DEP2 carries at the bottom of every
        # page (so a marker familiar with the report sees the same
        # provenance pattern).
        tags$h3("Credit"),
        p(
          "Created by ", strong("Wanting (Echo) Zhao"),
          " for Data Visualisation Project",
        ),
        # p(
        #   "Implemented in R 4.5.2 using ",
        #   tags$code("shiny"), ", ",
        #   tags$code("sf"), ", ",
        #   tags$code("dplyr"), ", ",
        #   tags$code("readr"), ", ",
        #   tags$code("leaflet"), ", ",
        #   tags$code("plotly"), ", ",
        #   tags$code("ggplot2"), ", and ",
        #   tags$code("viridisLite"), "."
        # ),

        # ----- Source code -----
        # Two GitHub repos: the DEP exploration repo (where the wrangling
        # script lives) and the DVP Shiny app repo (this code). External
        # link hardening as above.
        tags$h3("Source code"),
        tags$ul(
          tags$li(
            "DEP exploration repository: ",
            tags$a(
              href   = "https://github.com/EchoZhao1998/NYC_dog_neighbour",
              target = "_blank",
              rel    = "noopener noreferrer",
              "github.com/EchoZhao1998/NYC_dog_neighbour"
            )
          ),
          tags$li(
            "DVP Shiny app repository: ",
            tags$a(
              href   = "https://github.com/EchoZhao1998/5147-woof-ny-Rshiny-app",
              target = "_blank",
              rel    = "noopener noreferrer",
              "github.com/EchoZhao1998/5147-woof-ny-Rshiny-app"
            )
          )
        ),

        # ----- Acknowledgements -----
        # Thanks to the agencies that made the data available, plus the one
        # citation that earns its keep in the running app: Okabe & Ito's
        # colour-vision-deficiency-safe palette via Wong (Nature Methods
        # 2011), which we use across every borough-coloured view.
        tags$h3("Acknowledgements"),
        p(
          "Thank you for ", strong("Sarah Goodwin, Michael Niemann,"),
          strong("Ting Chai Wen, Ashwini Narasimhan, Mohit Gupta,"),
          " and FIT5147 Data Visualisation Project teaching team"
        ),

        # p(
        #   "Thanks to ", strong("NYC Open Data"), ", the ",
        #   strong("NYC Department of Health and Mental Hygiene"), ", the ",
        #   strong("NYC Parks Department"), ", and the ",
        #   strong("US Census Bureau"), " for keeping these datasets ",
        #   "openly accessible. The borough colour palette is the ",
        #   "Okabe-Ito (2008) Color Universal Design scheme, cited via Wong, ",
        #   em("Nature Methods"), " 8, 441 (2011) - chosen so the five ",
        #   "boroughs remain distinguishable to readers with red-green ",
        #   "colour vision deficiency."
        # ),

        # ----- Footer (AI declaration pointer + copyright) -----
        # Two stacked <small> lines, separated from the main content by an
        # <hr>. The AI declaration line is the one concession to the
        # FIT5147 brief - the brief (page 8) requires the declaration "at
        # the end of your report", NOT in the app itself, so this is just a
        # transparent breadcrumb pointing the marker at where the full
        # declaration lives. The copyright line is at Echo's request.
        tags$hr(),
        # tags$small(
        #   style = "color: #525252; display: block; margin-bottom: 0.25rem;",
        #   "A full Generative AI declaration is included at the end of the ",
        #   "accompanying Part 2 report, as required by the FIT5147 brief."
        # ),
        tags$small(
          style = "color: #525252; display: block;",
          "© 2026 Wanting (Echo) Zhao. All rights reserved."
        )
      ),
      br()
    )
  )
)


# ============================================================================
# 6. SERVER
# ============================================================================

server <- function(input, output, session) {

  # ---- Tab 1: Introduction borough reference map ------------------------
  # Pure rendering — no reactive inputs. The plot is static; we use
  # renderPlot rather than pre-rendering to PNG because (a) it's quick to
  # draw five polygons, and (b) keeping the ggplot code in app.R means
  # the marker can see exactly how the map is constructed.
  output$intro_borough_map <- renderPlot({
    ggplot() +
      geom_sf(
        data      = nyc_boroughs_map,
        aes(fill  = borough),
        colour    = "white",
        linewidth = 0.6
      ) +
      geom_text(
        data     = borough_centroids,
        aes(x = lon, y = lat, label = borough),
        size     = 4,
        fontface = "bold",
        colour   = "#1F2933"
      ) +
      scale_fill_manual(values = borough_colours, guide = "none") +
      theme_void(base_size = 12) +
      theme(plot.margin = margin(5, 5, 5, 5))
  })


  # ---- Tab 2: Trends ----------------------------------------------------
  # Reactive: filter bites_per_year_borough by the checkbox group.
  # req() short-circuits the reactive chain when input$tab2_boroughs is
  # NULL or an empty vector (i.e. user has unticked every borough). The
  # downstream renderPlotly() outputs then return silently rather than
  # throwing an error -> the charts go blank, which is the graceful UX
  # for "you've filtered out everything".
  selected_bites <- reactive({
    req(input$tab2_boroughs)
    bites_per_year_borough |>
      dplyr::filter(borough %in% input$tab2_boroughs)
  })

  # ---- Tab 2 chart ------------------------------------------------------
  # plot_ly() is preferred over ggplotly() here because:
  #   * ggplotly() unreliably translates annotate("rect", ...) - the COVID
  #     band sometimes disappears in the converted plotly JSON.
  #   * Native plot_ly + layout(shapes=, annotations=) is documented and
  #     stable (plotly.R reference, "layout > shapes").
  #   * Pre-built hover string via text= gives clean per-row tooltip
  #     control, which we need for the YoY % and 2020/2022 context flag.
  #
  # color = ~borough creates one trace per borough; colors = borough_colours
  # maps each trace to its Okabe-Ito hex (decision #3 in HANDOVER).
  # mode = "lines+markers" ports geom_line() + geom_point() from the
  # original DEP plot1b.
  #
  # The hover string is built in a mutate() so we can use
  # format(big.mark=",", trim=TRUE) for thousands separators and
  # ifelse(nzchar(...)) to conditionally add the COVID-year /
  # Post-COVID-peak context line. plotly receives the per-row string via
  # text = ~tooltip_text and renders it verbatim with
  # hovertemplate = "%{text}<extra></extra>". <b>...</b> and <i>...</i>
  # are HTML tags plotly honours inside hovers; <extra></extra>
  # suppresses plotly's default secondary trace-name box on the right.
  output$tab2_chart <- renderPlotly({
    df <- selected_bites() |>
      dplyr::mutate(
        tooltip_text = paste0(
          "<b>", borough, " ", year, "</b><br>",
          "Bites: ", format(bite_count, big.mark = ",", trim = TRUE), "<br>",
          "Year-on-year: ", yoy_label,
          ifelse(nzchar(note),
                 paste0("<br><i>", note, "</i>"),
                 "")
        )
      )

    plot_ly(
      data   = df,
      x      = ~year,
      y      = ~bite_count,
      color  = ~borough,
      colors = borough_colours,
      type   = "scatter",
      mode   = "lines+markers",
      line   = list(width = 2.5),
      marker = list(size  = 8),
      text   = ~tooltip_text,
      hovertemplate = "%{text}<extra></extra>"
    ) |>
      tab2_apply_layout()
  })


  # ---- Tab 3: Infrastructure -------------------------------------------
  # Two-part rendering pattern:
  #   1) renderLeaflet draws the BASE map once - tiles, view, and the 91
  #      dog-run circle markers (these don't change when the toggle flips).
  #   2) observeEvent + leafletProxy mutates only the choropleth layer +
  #      legend when input$tab3_metric changes.
  #
  # Why the split: re-running renderLeaflet on every radio click would
  # re-fetch tiles, reset the zoom/pan, and re-render the markers - all
  # wasted work. leafletProxy is the documented Shiny-leaflet idiom for
  # partial updates (leaflet R package vignette: "Modifying Existing Maps
  # with leafletProxy").
  output$tab3_map <- renderLeaflet({
    leaflet(options = leafletOptions(zoomControl = TRUE)) |>
      # arrange the layer order
      # so that audience can access park infomation when apply choropleth
      addMapPane("polygons", zIndex = 410) |>
      addMapPane("markers",  zIndex = 420) |>

      # CartoDB Positron: low-contrast tile so the choropleth fill carries
      # the colour story without competing with tile texture (standard
      # pairing for thematic choropleths).
      addProviderTiles(
        providers$CartoDB.Positron,
        options = providerTileOptions(opacity = 0.95)
      ) |>

      # Centre on NYC. lng/lat picked to fit all five boroughs at zoom 10
      # without cropping Staten Island.
      setView(lng = -73.95, lat = 40.72, zoom = 10) |>
      # Dog-run markers are part of the base layer because they're invariant
      # across the toggle. Neutral dark dot + white halo: reads cleanly on
      # both plasma and viridis backgrounds. We deliberately do NOT colour
      # them by borough - borough is already encoded by the ZCTA underneath
      # (position channel), so adding a colour channel here would be
      # redundant and clash with whichever palette is active.
      addCircleMarkers(
        data        = dog_run_centroids,
        lng         = ~lon,
        lat         = ~lat,
        options = pathOptions(pane = "markers"),
        radius      = 4,
        fillColor   = "#40B0A6",
        color       = "#FFFFFF",
        weight      = 1,
        fillOpacity = 0.9,
        group       = "dog_runs",
        # popup = click-to-pin, for named entities (each run has a NAME).
        # Distinct from the polygon `label` which is hover-only for
        # statistical regions - this label/popup split is the leaflet
        # idiom for "context tag" vs "named place".
        popup       = ~paste0(
          "<strong>", NAME, "</strong><br>", borough
        )
      )
  })

  # Observer: whenever the radio toggle changes, swap the choropleth layer
  # and legend.
  #
  # clearGroup("choropleth") removes only the polygons we tagged with
  # group = "choropleth" (the markers, on group = "dog_runs", are untouched).
  # clearControls() removes the legend so we can replace it.
  #
  # The four metric-specific values (fill_values, pal_fn, legend_title,
  # legend_format) are bound at the top of the observer so the single
  # addPolygons + addLegend call below stays branch-free. Easier to read
  # than two duplicated 15-line branches.
  observeEvent(input$tab3_metric, {

    is_density <- input$tab3_metric == "density"

    # For density we pass sqrt-transformed values (the palette was fitted
    # on sqrt(domain) in section 3f). For gap_index, no transform.
    fill_values <- if (is_density) {
      sqrt(master_filtered$dog_density)
    } else {
      master_filtered$gap_index
    }

    pal_fn <- if (is_density) pal_density else pal_gap

    legend_title <- if (is_density) {
      htmltools::HTML("Dog density<br>(dogs / km<sup>2</sup>, 2022)")
    } else {
      "Gap index"
    }

    # Density legend back-transforms with x^2 so tick labels read in
    # original dogs/km^2, not sqrt units. big.mark = "," for thousands.
    legend_format <- if (is_density) {
      labelFormat(transform = function(x) x^2, digits = 0, big.mark = ",")
    } else {
      labelFormat(digits = 2)
    }

    leafletProxy("tab3_map") |>
      clearGroup("choropleth") |>
      clearControls() |>
      addPolygons(
        data         = master_filtered,
        options      = pathOptions(pane = "polygons"), # put the dot map at fount
        weight       = 0.5,
        color        = "#FFFFFF",       # white separator hairlines
        fillColor    = pal_fn(fill_values),
        fillOpacity  = 0.65,
        label        = tab3_polygon_labels,
        labelOptions = labelOptions(
          # Match the app's Futura cascade so the tooltip doesn't switch
          # to leaflet's default Helvetica.
          style    = list(
            "font-family" = paste(
              "'Futura', 'Avenir Next', 'Trebuchet MS', sans-serif"
            ),
            "font-size"   = "13px",
            "padding"     = "6px 10px"
          ),
          textsize  = "13px",
          direction = "auto"
        ),
        # On hover: thicker dark border, NO fill colour change. Changing the
        # fill on hover destroys the colour encoding (Munzner ch.11:
        # interactive linking should not disrupt the static encoding).
        highlightOptions = highlightOptions(
          weight       = 2,
          color        = "#1F2933",
          bringToFront = TRUE
        ),
        group = "choropleth"
      ) |>
      addLegend(
        position  = "bottomright",
        pal       = pal_fn,
        values    = fill_values,
        title     = legend_title,
        labFormat = legend_format,
        opacity   = 0.85
      )
  })


  # ---- Tab 4: Safety - bite-rate choropleth ----------------------------
  # Single renderLeaflet block. Unlike Tab 3 we deliberately do NOT use the
  # leafletProxy + observeEvent split: there is no toggle / radio input on
  # this tab that the map responds to, so the "draw base + mutate on
  # update" pattern would be over-engineering. One render call, no
  # observers, lighter to reason about.
  #
  # Encoding: fill = bite_rate, palette = pal_bites (rocket reversed, see
  # section 3g). White hairline borders separate ZCTAs at zoom 10 without
  # competing with the fill. fillOpacity 0.7 chosen empirically - dense
  # enough that the colour reads on light Positron tiles, transparent
  # enough that borough boundaries underneath remain visible.
  #
  # na.label = "No data" on the legend adds a small grey swatch matching
  # pal_bites's na.color, so the handful of zero-dog ZCTAs are explained
  # in the legend rather than appearing as unaccounted-for grey patches.
  output$tab4_map <- renderLeaflet({
    leaflet() |>
      addProviderTiles(
        providers$CartoDB.Positron,
        options = providerTileOptions(opacity = 0.95)
      ) |>
      setView(lng = -73.95, lat = 40.72, zoom = 10) |>
      addPolygons(
        data         = master_filtered,
        weight       = 0.5,
        color        = "#FFFFFF",
        fillColor    = pal_bites(master_filtered$bite_rate),
        fillOpacity  = 0.7,
        label        = tab4_polygon_labels,
        labelOptions = labelOptions(
          style    = list(
            "font-family" = paste(
              "'Futura', 'Avenir Next', 'Trebuchet MS', sans-serif"
            ),
            "font-size"   = "13px",
            "padding"     = "6px 10px"
          ),
          textsize  = "13px",
          direction = "auto"
        ),
        # Hover: thicker dark border ONLY. Same Munzner ch.11 reasoning as
        # Tab 3 - do not mutate the fill on hover, that would destroy the
        # colour encoding we just established.
        highlightOptions = highlightOptions(
          weight       = 2,
          color        = "#1F2933",
          bringToFront = TRUE
        )
      ) |>
      addLegend(
        position  = "bottomright",
        pal       = pal_bites,
        values    = master_filtered$bite_rate,
        title     = htmltools::HTML(
          "Bite rate<br>(per 1,000 dogs,<br>2016&ndash;2023)"
        ),
        labFormat = labelFormat(digits = 1),
        opacity   = 0.85,
        na.label  = "No data"
      )
  })


  # ---- Tab 4: Safety - income x bite_rate scatter ----------------------
  # plot_ly native (not ggplotly), matching the Trends-tab convention so
  # the codebase has ONE plotly idiom instead of two.
  #
  # color = ~borough produces one trace per borough; colors = borough_colours
  # maps each trace to its Okabe-Ito hex (decision #3) so borough colour
  # reads consistently with the Trends line chart.
  #
  # marker$line is a 0.5px white halo - the Cleveland (1985) fix for
  # overplotting where many Manhattan ZCTAs cluster at the high-income /
  # low-bite end. Same halo trick we used on the Tab 3 dog-run markers.
  #
  # tickformat = "$,d" prints "$30,000" instead of "30000". rangemode
  # "tozero" on y forces the bite-rate axis to start at zero (Munzner
  # ch.6: non-zero baselines on quantitative scatters mislead the eye).
  # config(displayModeBar = FALSE) hides plotly's toolbar - we want a
  # reading-the-story interaction, not a fiddle-with-the-chart one (same
  # rationale as tab2_apply_layout).
  output$tab4_scatter <- renderPlotly({
    plot_ly(
      data   = tab4_scatter_data,
      x      = ~median_income,
      y      = ~bite_rate,
      color  = ~borough,
      colors = borough_colours,
      type   = "scatter",
      mode   = "markers",
      marker = list(
        size    = 9,
        opacity = 0.75,
        line    = list(width = 0.5, color = "#FFFFFF")
      ),
      text          = ~tooltip_text,
      hovertemplate = "%{text}<extra></extra>"
    ) |>
      layout(
        xaxis  = list(
          title      = "Median household income (USD)",
          tickformat = "$,d"

        ),
        yaxis  = list(
          title     = "Bite rate (per 1,000 dogs, 2016–2023)",
          rangemode = "tozero"
        ),
        legend = list(
          title = list(text = "Borough"),
          orientation = "h",
          x = 0,
          y = 1.12
        ),
        margin = list(t = 70, r = 20, b = 60, l = 70)
      ) |>
      config(displayModeBar = FALSE)
  })

}


# ============================================================================
# 7. RUN
# ============================================================================
shinyApp(ui = ui, server = server)
