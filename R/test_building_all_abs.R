

library(stringr)

excel_path   <- "data/seminars.xlsx"
excel_sheet  <- "AY2025-2026 Sem 1"  # adjust if your sheet name changes
skip_rows    <- 1
emails_out   <- "Seminar_emails/outputs"
dir.create(emails_out, showWarnings = FALSE, recursive = TRUE)

# If you want to pick by week number, set this. Otherwise it’ll auto-pick by date.
this_week_no <- 1  # can be overridden by env var THIS_WEEK_NO on CI

env_week <- Sys.getenv("THIS_WEEK_NO", unset = NA)
if (!is.na(env_week) && nzchar(env_week)) {
  this_week_no <- as.integer(env_week)
}

# ---- READ + CLEAN ----
details <- read_excel(path = excel_path, sheet = excel_sheet, skip = skip_rows) |>
  clean_names() |>
  filter(!is.na(presenter)) |>
  mutate(
    date = as_date(date),
    date_fancy = map_chr(date, formatted_date)
  )

menu_lines <- c(
  "website:",
  "  navbar:",
  "    left:",
  "      - text: \"Abstracts\"",
  "        menu:"
)

# for(i in nrow(details)){
for(i in 1:3){
  # Strategy A (original): pick by a manual week number
  seminars_this_week <- details |>
    slice(i)
  
  # ---- Build params for the main weekly email ----
  seminar_par <- list(
    presenter             = nz(seminars_this_week$presenter),
    affiliation           = nz(seminars_this_week$affiliation),
    date_fancy            = nz(as.character(seminars_this_week$date_fancy)),
    date                  = nz(as.character(seminars_this_week$date)),
    time                  = nz(seminars_this_week$time),
    departmental_contact = nz(seminars_this_week$departmental_contact),
    title                 = nz(seminars_this_week$title),
    abstract              = nz(seminars_this_week$abstract)
  )
  
  row <- details[i,]
  
  # make a stable filename (slug)
  slug <- row |>
    (\(r) glue("{r$date}-{r$presenter}-{r$title}"))() |>
    str_squish() |> str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_replace_all("(^-|-$)", "")
  
  # ---- Render your two email templates ----
  # Main weekly email (with schedule)
  quarto_render(
    input       = "./seminar_abstract_web_template.qmd",
    execute_params = seminar_par,
    output_file = glue("{slug}.html"),
    # output_dir = "abstracts"
    quarto_args    = c(
      "--profile", "abstracts",  
      "--output-dir", "abstracts",   # folder (relative to project root)
      "-o", paste0(slug, ".html")    # filename only (no path!)
    )
  )
  
  # add a dropdown item (escape double quotes in text)
  label <- glue("{format(row$date, '%d %b %Y')} — {row$presenter}")
  label <- gsub('"', '\\"', label)
  
  menu_lines <- c(
    menu_lines,
    glue('          - text: "{label}"'),
    glue('            href: /abstracts/{slug}.html')
  )
}


# write the YAML at project root
writeLines(menu_lines, "_nav_abstracts.yml")



# test  -------------------------------------------------------------------


