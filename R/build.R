###########################################################################
## Project: MACSi seminar series
## Script purpose: create a series of csv and ics files for the sites
## Date: 10/09/2025
## Author: David JP O'Sullivan
###########################################################################

# R/build.R
# Run on CI before rendering the site

source("R/helpers.R")

# data for this current sem  -----------------------------------------------------------


# next sem open slots
output_file = "data/AY26-27_sem_1_timetable.csv" 
excel_sheet = "AY2026-2027 Sem 1"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)

# current 
output_file = "data/AY25-26_sem_2_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 2"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)


# older sems --------------------------------------------------------------

output_file = "data/AY25-26_sem_1_timetable.csv" 
excel_sheet = "AY2025-2026 Sem 1"
excel_path = "data/MACSI seminar series.xlsx"
create_timetable_csv(output_file, excel_sheet, excel_path)


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

csv_path <- "./data/AY25-26_sem_2_timetable.csv"
ics_out  <- "calendar/macsi-seminar-series.ics"
create_ics_seminar_series(csv_path, ics_out)




