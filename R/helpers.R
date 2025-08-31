formatted_date <- function(x) {
  x <- as.Date(x)
  format(x, "%a %d %b %Y")
}

# Safe NA -> ""
nz <- function(x) ifelse(is.na(x), "", x)

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
    set_caption("Upcoming MACSI Seminars")
  return(seminar_table)
}


create_abstracts_text <- function(seminars_pre){
  
  seminars_pre_filterd <- 
    seminars_pre |> 
    mutate(abstract = stringr::str_trim(abstract)) |> 
    filter(!(abstract %in% c("TBC","TBA","Friday","")))
  
  for (i in seq_len(nrow(seminars_pre_filterd))) {
    text <- glue::glue("

## Seminar week {seminars_pre_filterd$week_no[i]} by {seminars_pre_filterd$presenter[i]}

**Date:** {seminars_pre_filterd$date[i]} at {seminars_pre_filterd$time[i]}  
**Speaker:** {seminars_pre_filterd$presenter[i]} ({seminars_pre_filterd$affiliation[i]})  
**Host:** {seminars_pre_filterd$departmental_contact[i]}  

**Title:** {seminars_pre_filterd$title[i]}

**Abstract:** {seminars_pre_filterd$abstract[i]}

---


")
    cat(text)
  }
}
