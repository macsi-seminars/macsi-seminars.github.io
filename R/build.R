# R/build.R
# Run on CI before rendering the site

library(readxl)
library(dplyr)
library(purrr)
library(janitor)
library(lubridate)
library(readr)
library(glue)
library(quarto)

source("R/helpers.R")

create_timetable_csv <- function(output_file = "data/AY25-26_sem_1_timetable.csv", 
                                 excel_sheet = "AY2025-2026 Sem 1",
                                 excel_path = "data/Seminars.xlsx"){

  details <- read_excel(path = excel_path, sheet = excel_sheet, skip = 1) |>
    clean_names() |>
    filter(!is.na(presenter)) |>
    mutate(
      date = as_date(date),
      date_fancy = map_chr(date, formatted_date)
    )
  
  write_csv(details, file = output_file)
  
  print(glue::glue("Finished creating file {output_file} using sheet {excel_sheet}."))
}

# data for this current sem  -----------------------------------------------------------

# current 
output_file = "data/AY25-26_sem_1_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 1"
excel_path = "data/Seminars.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

# next sem open slots
output_file = "data/AY25-26_sem_2_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 2"
excel_path = "data/Seminars.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

# older sems --------------------------------------------------------------

output_file = "data/AY24-25_sem_2_timetable.csv"
excel_sheet = "AY2024-2025 Sem 2"
excel_path = "data/Seminars.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

output_file = "data/AY24-25_sem_1_timetable.csv"
excel_sheet = "AY2024-2025 Sem 1"
excel_path = "data/Seminars.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

output_file = "data/AY23-24_sem_2_timetable.csv"
excel_sheet = "AY2023-2024 Sem 2"
excel_path = "data/Seminars.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)






