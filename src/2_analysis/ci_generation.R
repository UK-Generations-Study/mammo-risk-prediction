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
library(BCRA) # GAIL SCORE

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")
source("../helper_functions/iCARE_validate_and_plot.R")
source("../helper_functions/append_event_and_risk.R")

eligible_dicoms_fn <- "../../../data/eligible_dicomuids_strategyB.csv"

study.data <- read.csv(eligible_dicoms_fn) %>%
  append_event_data() %>% append_risk_scores()

# Calculating residuals of mirai score (Y) ~ cumulus reading (X)
study.data <- study.data |>
  mutate(mirai_score_5y_sans_cumulus = residuals(lm(
    qlogis(mirai_score_5y) ~ cumulus_reading,# qlogis(cumulus_reading / 100),
    data = study.data,
    na.action=na.exclude
)))


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

# No filter: Mirai
cindex_compldata <- ci_calc(study.data, c("mirai_score_5y"))

# Remove >= 90yrs and <= 20 yrs: GAIL and Mirai
cindex_subsetdata <- ci_calc(study.data %>% filter(study.exit.age <= 90 & study.entry.age >= 20), c("gail_score", "mirai_score_5y"))

# Non-NA: Cumulus and Mirai
cindex_subsetdata <- ci_calc(study.data %>% filter(!is.na(cumulus_reading)), c("cumulus_reading", "mirai_score_5y"))