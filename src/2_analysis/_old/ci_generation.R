### C-index CALCULATIONS ###

# This code is intended to calculate C-indices for all risk scores considered in this analysis.
# Right-censoring occurs at the 5 year mark.

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
library(BCRA)   
library(readxl)
library(iCARE)
library(tidyr)
# GAIL SCORE

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/data_processing.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")
# source("../helper_functions/iCARE_validate_and_plot.R")
source("../helper_functions/append_event_and_risk.R")

# Read in eligible dicoms
eligible_dicoms_fn <- "../../../data/eligible_dicomuids_mammodate_strategyB_cumulus.csv"
eligible_dicom_uids <- read.csv(eligible_dicoms_fn)
study.data <- eligible_dicom_uids %>%
  append_event_data() %>% append_risk_scores(eligible_dicom_uids)

# Appending Transpara density
transpara_results_fn <- "../../../../transpara/transpara_risk/results/result.csv"
transpara_results <- read.csv(transpara_results_fn)
transpara_checkpoint_fn <- "../../../../transpara/transpara_risk/checkpoint/checkpoint.csv"
transpara_checkpoint <- read.csv(transpara_checkpoint_fn)
study.data.merged <- study.data %>% left_join(transpara_results, by = c('TCode' = 'accession'))
study.data.merged$avg_volumetric_breast_density <- (study.data.merged$volumetric_breast_density_left +
                                                      study.data.merged$volumetric_breast_density_right) / 2
plot(
  study.data.merged$cumulus_reading,
  study.data.merged$avg_volumetric_breast_density,
  xlim = c(0, 100),
  ylim = c(0, 100),
  xlab = "Cumulus Density",
  ylab = "Transpara Density",
  main = "Cumulus vs Transpara Density (n=231)"
)
abline(0, 1, col = "red", lwd = 2, lty = 2)

with(study.data.merged %>% filter(!is.na(cumulus_reading), !is.na(avg_volumetric_breast_density)), cor(cumulus_reading, avg_volumetric_breast_density))

# Calculating residuals of mirai score (Y) ~ cumulus reading (X)
study.data <- study.data |>
  mutate(mirai_score_5y_sans_cumulus = residuals(lm(
    qlogis(mirai_score_5y) ~ cumulus_reading,# qlogis(cumulus_reading / 100),
    data = study.data,
    na.action=na.exclude
)))


# MIRAI Expected/GAIL Expected
study.data |>
  summarise(expected_gail = sum(gail_score/100), expected_mirai = sum(mirai_score_5y)) |>
  mutate(e_e = expected_mirai/expected_gail) |>
  print()

# For each score, calculate CI and AUC (5-year)
ci_calc <- function(data, risk_scores) {
  c_indices <- list()
  
  for(score in risk_scores) {
    concordance_index <- with(data |> filter(!is.na(!!sym(score))) |> mutate(score = !!sym(score)), Cindex(risk = score, times = time.ci, delta = case_control_status))
    
    # Bootstrapping for C-Index
    ci_sample <- numeric(0)
    for(i in 1:5000){
      ci_sample[i] <- with(data |> filter(!is.na(!!sym(score))) |> mutate(score = !!sym(score)) |> sample_n(size = n(), replace = T), Cindex(risk = score, times = time.ci, delta = case_control_status))
    }
    
    ci_lower <- unname(quantile(ci_sample, probs = 0.025))
    ci_upper <- unname(quantile(ci_sample, probs = 0.975))
    
    c_indices[[score]] <- data.frame(cindex = concordance_index, lower = ci_lower, upper = ci_upper)
  }
  
  return(c_indices)
}

#############
# Execution #
#############

study.data <- study.data |> 
  mutate(gail_eligible = study.exit.age <= 90 & study.entry.age >= 20,
         cumulus_eligible = !is.na(cumulus_reading))
# All are Gail eligible (per >= 90yrs and <= 20 yrs criteria)

# No filter: Mirai
cindex_compldata <- ci_calc(study.data, c("gail_score", "mirai_score_5y", "iCARE_Lit_risk_5"))

# Only non-missing Cumulus reading eligible: Cumulus and Mirai
cindex_denssubsetdata <- ci_calc(study.data %>% filter(cumulus_eligible), c("gail_score", "cumulus_reading", "mirai_score_5y", "mirai_score_5y_sans_cumulus", "iCARE_Lit_risk_5"))
table(cumulus_available=study.data$cumulus_eligible)
prop.table(table(cumulus_available=study.data$cumulus_eligible))

## Table Generation

# Initialise dataframe
table3 <- data.frame(risk_score = character(0), c_index = character(0), c_index_sub = character(0))

for(score in names(cindex_denssubsetdata)){
  
  # Get subset C-index and CI
  ci_sub <- cindex_denssubsetdata[[score]]
  ci_sub <- paste0(sprintf("%.3f",ci_sub$cindex), " (", sprintf("%.3f",ci_sub$lower), ", ",sprintf("%.3f",ci_sub$upper), ")")
  
  # If it is in complete then grab that if not just output "-"
  if(score %in% names(cindex_compldata)){
    
    ci <- cindex_compldata[[score]]
    ci <- paste0(sprintf("%.3f",ci$cindex), " (", sprintf("%.3f",ci$lower), ", ", sprintf("%.3f",ci$upper), ")")
    
  } else {
    
    ci <- "-"
    
  }
  
  table3[nrow(table3) + 1,] <- c(score, ci, ci_sub)
  
}

# Table formatting
table3_gt <- table3 |>
  filter(risk_score != "iCARE_Lit_risk_5") |>
  mutate(risk_score = factor(risk_score, levels = c("gail_score", "mirai_score_5y", "cumulus_reading", "mirai_score_5y_sans_cumulus"), labels = c("GAIL", "Mirai", "Cumulus", "Mirai (adj. Cumulus)"))) |>
  arrange(risk_score) |>
  gt() |>
  cols_label(
    risk_score = md("**Risk Score**"),
    c_index = md("**C-Index (95% CI)**"),
    c_index_sub = md("**C-Index (95% CI)\n(Subset)**")
  )
  
gtsave(table3_gt, "../../results/tables/table_3.docx")
