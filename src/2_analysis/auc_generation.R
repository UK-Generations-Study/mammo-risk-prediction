### AUC CALCULATIONS ###

# This code is intended to calculate AUC values for all risk scores considered in this analysis.
# The AUCs will be over a 5 year time span

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


## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")

## Reading in data

# Risk scores
load_mirai_score <- function(score_csv) {
  read.csv(score_csv) %>%
    rename(TCode = patient_exam_id, mirai_score_5y = X5_year_risk) %>% 
    mutate(TCode = gsub("([A-Za-z\\d]+)(\t0)", '\\1', TCode, perl=T)) %>%
    dplyr::select(TCode, mirai_score_5y)
}
risk_mirai_strategyA <- load_mirai_score("../../../output/mirai_scores_strategyA.csv")
risk_mirai_strategyB <- load_mirai_score("../../../output/mirai_scores_strategyB.csv")

# Eligible DICOM UIDS
eligible_dicom <- list()
eligible_dicom[["A"]] <- read.csv("../../../data/eligible_dicomuids_strategyA.csv")
eligible_dicom[["B"]] <- read.csv("../../../data/eligible_dicomuids_strategyB.csv")

# Mammo images
data_images <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoImages_v1.csv")

# Cumulus scores
data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")

## Derive study population (for each strategy)

for(strategy in names(eligible_dicom)){
  
  # Get fup start dates from mammograms
  data_images_dates <- data_images |>
    filter(SOPInstanceUID %in% eligible_dicom[[strategy]]$SOPInstanceUID) |>
    group_by(TCode) |>
    summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
    ungroup()
  
  # Create analytical population
  study.data <- data_images_dates |>
    do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m"))
  
  ## ADD IN MIRAI WHEN COMPLETE ##
  study.data.2 <- study.data |>
    merge(if (strategy == 'A') risk_mirai_strategyA else risk_mirai_strategyB, by='TCode')
  
  # Add in Cumulus scores and report completeness
  cumulus_scores <- data_cumulus |>
    filter(SOPInstanceUID %in% eligible_dicom[[strategy]]$SOPInstanceUID) |>
    filter(Reader_ID != "JW") |>
    group_by(TCode) |>
    summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))
   
  # # All Cumulus scores
  # cumulus_scores_all <- data_cumulus |>
  #   filter(TCode %in% study.data$TCode) |>
  #   filter(Reader_ID != "JW") |>
  #   group_by(TCode) |>
  #   summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))
  # 
  # print(nrow(cumulus_scores_all))
  
  study.data.3 <- study.data.2 |>
    merge(cumulus_scores, by = "TCode", all.x = T)
  
  print(table(is.na(study.data.3$cumulus_reading)))
  
  # Add in GAIL scores
  gail_scores <- study.data.3 |>
    select(TCode, study.entry.age, study.exit.age) |>
    filter(study.exit.age <= 90 & study.entry.age >= 20) |>
    do(GAIL_score_generation(.))
  
  study.data.4 <- study.data.3 |>
    merge(gail_scores, by = "TCode", all.x = T)
  
  # Ground truth case-control status
  study.data.5 <- study.data.4 |>
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
  
  # For each score (ADD IN MIRAI) calculate CI and AUC (5-year)
  # Loop through scores calculating relevant metrics
  for(score in c("gail_score", "cumulus_reading", "mirai_score_5y")){
    
    auc <- suppressWarnings(auc(study.data.5$case_control_status, study.data.5[[score]]))
    ci <- pROC::ci(auc)
    
    concordance_index <- with(study.data.5 |> filter(!is.na(!!sym(score))) |> mutate(score = !!sym(score)), Cindex(risk = score, times = time.ci, delta = case_control_status))
    
    # Bootstrapping for C-Index
    ci_sample <- numeric(0)
    for(i in 1:100){
      ci_sample[i] <- with(study.data.5 |> filter(!is.na(!!sym(score))) |> mutate(score = !!sym(score)) |> sample_n(size = n(), replace = T), Cindex(risk = score, times = time.ci, delta = case_control_status))
    }
    
    ci_lower <- quantile(ci_sample, probs = 0.025)
    ci_upper <- quantile(ci_sample, probs = 0.975)
    ci_ci <- c(ci_lower, ci_upper)
    
    cat(paste0("AUC for ", score, ": ", round(auc, 5), " (" , paste0(round(ci[-2], 5), collapse = ", "), ")", "\n"))
    
    cat(paste0("Concordance Index for ", score, ": ", round(concordance_index, 5), " (" , paste0(round(ci_ci, 5), collapse = ", "), ")","\n"))
    
  }
  
  # overall_expected <- mean(study.data.5$mirai_score_5y, na.rm = TRUE)
  # overall_observed <- mean(study.data.5$case_control_status == 1, na.rm = TRUE)
  # 
  # calibration <- study.data.5 %>% 
  #   mutate(decile = ntile(mirai_score_5y, 10)) %>% 
  #   group_by(decile) %>% 
  #   summarise(
  #     expected = mean(mirai_score_5y, na.rm = TRUE), 
  #     observed = mean(case_control_status == 1, na.rm = TRUE),
  #     .groups = "drop"
  #   ) %>%
  #   mutate(
  #     predicted_rr = expected / overall_expected,
  #     observed_rr = observed / overall_observed
  #   )
  # 
  # print(paste0('Relative Risk Calibration of Mirai risk scores for strategy ', strategy, ':'))
  # print(calibration)

}


