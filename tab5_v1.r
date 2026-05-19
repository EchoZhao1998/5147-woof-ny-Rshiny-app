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