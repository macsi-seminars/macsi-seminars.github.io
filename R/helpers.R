###########################################################################
## Project: MACSI Seminar webpage
## Script purpose: helper function and packages
## Author: David JP O'Sullivan
###########################################################################


# load packages -----------------------------------------------------------

library(readxl)
library(dplyr)
library(purrr)
library(janitor)
library(lubridate)
library(readr)
library(glue)
library(quarto)
library(stringr)
library(calendar)


# general functions -------------------------------------------------------

# Define a custom function to add ordinal suffix to days
add_ordinal_suffix <- function(day) {
  if (day %% 10 == 1 && day %% 100 != 11) {
    return(paste0(day, "st"))
  } else if (day %% 10 == 2 && day %% 100 != 12) {
    return(paste0(day, "nd"))
  } else if (day %% 10 == 3 && day %% 100 != 13) {
    return(paste0(day, "rd"))
  } else {
    return(paste0(day, "th"))
  }
}

# Function to format dates in a custom format
formatted_date <- function(date) {
  paste0(
    weekdays(date), " the ", 
    add_ordinal_suffix(day(date)), 
    " of ", 
    month(date, label = TRUE, abbr = FALSE), 
    " ", 
    year(date)
  )
}

# Safe NA -> ""
nz <- function(x) ifelse(is.na(x), "", x)

# create each pages csv from the excel spread sheet
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

# from a data frame create the timetable
create_timetable <- function(seminars_pre){
  seminars <- seminars_pre |>
    select(date,day_of_week, time, week_no, presenter, affiliation,
           departmental_contact, title) |> 
    rename(
      Date = date,
      "Day" = day_of_week,
      Time = time, 
      "Week no." = week_no,
      Presenter = presenter, 
      "Affil." = affiliation, 
      "Dept. Contact" = departmental_contact, 
      "Title" = title
    )
  
  library(flextable)
  library(xtable)
  # Create a nicely formatted table with flextable
  seminar_table <- flextable(seminars) |>
    theme_vanilla() |>    # Apply a clean theme
    autofit() |>        # Auto-size columns
    fontsize(size = 11) |> 
    font(fontname = "Lato", part = "all") |>  
    set_caption("Upcoming MACSI Seminars")
  return(seminar_table)
}

# from a data frame create the abstract text
create_abstracts_text <- function(seminars_pre){
  
  seminars_pre_filterd <- 
    seminars_pre |> 
    mutate(abstract = stringr::str_trim(abstract)) |> 
    filter(!(abstract %in% c("TBC","TBA","Friday","")))
  
  for (i in seq_len(nrow(seminars_pre_filterd))) {
    
    icon_text <- create_icons_and_links(seminars_pre_filterd, i)
    
    text <- glue::glue("

## Seminar week {seminars_pre_filterd$week_no[i]} by {seminars_pre_filterd$presenter[i]}

**Date:** {seminars_pre_filterd$date[i]} at {seminars_pre_filterd$time[i]}  
**Speaker:** {seminars_pre_filterd$presenter[i]} ({seminars_pre_filterd$affiliation[i]})  
**Host:** {seminars_pre_filterd$departmental_contact[i]}  

**Title:** {seminars_pre_filterd$title[i]}

**Abstract:** {seminars_pre_filterd$abstract[i]}

{icon_text}


---


")
    cat(text)
  }
}


# create the icon for abstracts -------------------------------------------

# if multiple url are present split on ";"
split_semicolon_urls <- function(x) {
  stringr::str_split(x, ";", n = Inf)[[1]] |>
    stringr::str_trim()
}

# from a single cell of url build the icons
build_paper_icon <- function(url){
  url <- split_semicolon_urls(url)
  
  if(length(url) == 1){
    text <- glue('<span class="bi bi-journal-text"></span> [Speaker\'s Paper]({url})')
  } else {
    text <- ""
    for(j in seq_along(url)){
      text <- glue::glue('{text}
                   <span class="bi bi-journal-text"></span> [Speaker\'s Paper {j}]({url[j]})
                   ')
    }
  }
  return(text)
}

# for all icon we want to build create the text.
create_icons_and_links <- function(seminars_pre, i){
  
  paper_url <- seminars_pre$link_to_paper[i]
  gs_url <- seminars_pre$google_scholar_profile[i]
  
  if(!is.na(paper_url)){
    paper_icon <- build_paper_icon(paper_url)
  } else {
    paper_icon <- ""
  }
  
  if(!is.na(gs_url)){
    gs_icon <- glue::glue('<span class="bi bi-google"></span> [Speaker\'s Google Scholar]({gs_url})')
  } else {
    gs_icon <- ""
  }
  
  text <- glue::glue("
                     {gs_icon} 
                     
                     {paper_icon}
                     ")
  return(text)
}


# create ics file for website ---------------------------------------------

# read in the seminar series csv and build the events for a calendar.
create_ics_seminar_series <- function(csv_path, ics_out){
  df <- read_csv(csv_path, show_col_types = FALSE)
  events <- df |>
    rowwise() |>
    mutate(
      start_time = lubridate::ymd_h(
        glue::glue("{date} {time}"), tz = "Europe/Dublin"
      ),
      end_time = start_time + hours(1),
      summary = str_squish(glue::glue(
        "MACSI Seminar: Week no {week_no} given by {presenter}"
      )),
      description = str_squish(
        "See seminar schedule and abstracts at https://macsi-seminars.github.io/"
      ),
      ev = ic_event(
        start_time = start_time,
        end_time = end_time,
        summary = summary
      )
    ) |>
    ungroup()
  
  ics <- events$ev
  ics <- ics |> mutate(DESCRIPTION = events$description)
  ical(ics) |> ic_write(file = ics_out)
  cat("Wrote floating-time ICS to:", ics_out, "\n")
}
