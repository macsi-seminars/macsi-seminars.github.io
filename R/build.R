# R/build.R
# Run on CI before rendering the site

source("R/helpers.R")

# data for this current sem  -----------------------------------------------------------

# current 
output_file = "data/AY25-26_sem_1_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 1"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

# next sem open slots
output_file = "data/AY25-26_sem_2_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 2"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

# older sems --------------------------------------------------------------

output_file = "data/AY24-25_sem_2_timetable.csv"
excel_sheet = "AY2024-2025 Sem 2"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

output_file = "data/AY24-25_sem_1_timetable.csv"
excel_sheet = "AY2024-2025 Sem 1"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

output_file = "data/AY23-24_sem_2_timetable.csv"
excel_sheet = "AY2023-2024 Sem 2"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)



# create calendar ---------------------------------------------------------



# --- config ----------------------------------------------------------
csv_path <- "./data/AY25-26_sem_1_timetable.csv"
ics_out  <- "calendar/macsi-seminar-series.ics"

# --- load data -------------------------------------------------------
df <- read_csv(csv_path, show_col_types = FALSE)
events <- df |>
  rowwise() |>
  mutate(
    start_time = lubridate::ymd_h(glue::glue("{date} {time}"), tz = "Europe/Dublin"),
    end_time   = start_time + hours(1),
    summary = str_squish(glue::glue(
      "MACSI Seminar: Week no {week_no} given by {presenter}"
    )),
    description = str_squish("See seminar schedule and abstracts at https://macsi-seminars.github.io/"),
    ev = ic_event(
      start_time = start_time,
      end_time   = end_time,
      summary    = summary
    )
  ) |>
  ungroup()

ics <- events$ev
ics <- ics |> mutate(DESCRIPTION = events$description)
ical(ics) |> ic_write(file = ics_out)
cat("Wrote floating-time ICS to:", ics_out, "\n")



