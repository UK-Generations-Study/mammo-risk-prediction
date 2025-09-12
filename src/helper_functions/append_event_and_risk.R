## Packages
library(ggplot2)
library(dplyr)
library(readr)
library(sqldf)
library(stringr)
library(lubridate)
library(gt)
library(pROC)
library(crosstable)
library(readxl)
library(Hmisc)
library(nftbart)
library(BCRA) # GAIL SCORE

## Functions
source("../helper_functions/data_processing.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")
source("../1_score_generation/iCARE_Lit_score_generation.R")
source("../helper_functions/iCARE_validate_and_plot.R")


dicom_metadata_fn <- "//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoImages_v1.csv"
set_metadata_fn <- "//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoSet_v1.csv"

# Append incident cancers to passed DICOM UIDs
append_event_data <- function(eligible_dicom_uids, dicom_metadata = NULL, set_metadata = NULL)  {
  #browser()
  if(length(dim(eligible_dicom_uids))) # Handle passing dataframe
    eligible_dicom_uids <- eligible_dicom_uids[,1]
  
  if(is.null(dicom_metadata))
    dicom_metadata <- read.csv(dicom_metadata_fn)
  
  if(is.null(set_metadata))
    set_metadata <- read.csv(set_metadata_fn)
  
  # Get fup start dates from mammograms
  dicom_data <- dicom_metadata |>
    filter(SOPInstanceUID %in% eligible_dicom_uids) |>
    #left_join(set_metadata %>% select(SOPInstanceUID, YearOfMammo), by='SOPInstanceUID') |>
    group_by(TCode) |>
    summarise(#YearOfMammo = unique(YearOfMammo),
              StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
    ungroup()
  
  # Create analytical population
  study_data <- dicom_data |>
    do(create_analytical_dataset(., years = NA, cancer = "all_breast", fup_start_date = "StudyDate_m"))
  
  study_data <- study_data |>
    mutate(
      
      case_control_status = case_when(
        time.of.onset > 5 | time.of.onset > (study.exit.age - study.entry.age) ~ 0,
        TRUE ~ 1
      ),
      
      #time.ci = pmin(time.of.onset, 5)
      time.ci = case_when(
        case_control_status == 0 ~ pmin(study.exit.age - study.entry.age, 5),
        TRUE ~ pmin(time.of.onset, 5)
      )
      
    )
  
  return(study_data)
}

append_risk_scores <- function(data, eligible_dicom_uids, return_data=F) {
  if(length(dim(eligible_dicom_uids))) # Handle passing dataframe
    eligible_dicom_uids <- eligible_dicom_uids[,1]
  # Append Mirai scores
  load_mirai_score <- function(score_csv) {
    read.csv(score_csv) %>%
      rename(TCode = patient_exam_id, mirai_score_5y = X5_year_risk) %>% 
      mutate(TCode = gsub("([A-Za-z\\d]+)(\t0)", '\\1', TCode, perl=T)) %>%
      dplyr::select(TCode, mirai_score_5y)
  }
  risk_mirai <- load_mirai_score("../../../output/risk_scores/mirai_scores.csv")
  data <- data |>
    merge(risk_mirai, by='TCode')
  #browser()
    # Append Cumulus scores
  data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")  
  cumulus_scores <- data_cumulus |>
    filter(SOPInstanceUID %in% eligible_dicom_uids) |>
    filter(Reader_ID != "JW") |>
    group_by(TCode) |>
    summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))
  
  data <- data |>
    merge(cumulus_scores, by = "TCode", all.x = T)
  
  # Append GAIL scores
  gail_filter <- data |>
    select(TCode, study.entry.age, study.exit.age) |>
    filter(study.exit.age <= 90 & study.entry.age >= 20)

  gail_output <-  GAIL_score_generation(gail_filter)
  
  data <- data |>
    merge(gail_output$scores, by = "TCode", all.x = T)
  
  # Append iCARE-Lit scores
  iCARE_output <- iCARE_Lit_score_generation(data |> select(TCode, study.entry.age))
  
  data <- data |>
    merge(iCARE_output$scores, by = "TCode", all.x = T)
  
  if(return_data)
    return(list(output=data, gail_data=gail_output$data, iCARE_Lit_data = iCARE_output$data))
  else
    return(data)
}
