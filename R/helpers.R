

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


create_timetable <- function(seminars_pre){
  seminars <- seminars_pre |>
    select(date, time, week_no, presenter, affiliation,
           departmental_contact, title) |> 
    rename(
      Date = date,
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


split_semicolon_urls <- function(x) {
  stringr::str_split(x, ";", n = Inf)[[1]] |>
    stringr::str_trim()
}

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