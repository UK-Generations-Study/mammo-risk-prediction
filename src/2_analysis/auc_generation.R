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


## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")

## Reading in data

# Risk scores
risk_mirai <- read.csv("../../../output/risk_scores/mirai_scores.csv")
risk_tc <- read.csv("../../../output/risk_scores/TC_risk_scores.csv")
risk_cumulus <- read.csv("../../../output/risk_scores/cumulus_scores.csv")

# Eligible DICOM UIDS
eligible_dicom <- read.csv("../../../data/eligible_dicomuids.csv")

# Mammo images
data_images <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoImages_v1.csv")

# Data cancer
data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv")

## Derive study population

# Getting list of MIRAI scores and also obtaining from those the date of the mammogram to use as the date at the start of follow up
study.data <- risk_mirai |>
  mutate(TCode = gsub("\\s.*", "", patient_exam_id),
         absrisk_5 = X5_year_risk,
         .keep = "none")

# Getting mammmo date from data_images, using the UID of the images used for MIRAI
data_images_dates <- data_images |>
  filter(TCode %in% study.data$TCode) |>
  filter(SOPInstanceUID %in% eligible_dicom$SOPInstanceUID) |>
  group_by(TCode) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

# Merging back into study.data and creating an analytical study population
study.data.fup <- study.data |>
  merge(data_images_dates, by = "TCode") |>
  do(create_analytical_dataset(., years = 5, cancer = "breast", fup_start_date = "StudyDate_m", data_cancer = data_cancer)) |>
  rename(absrisk_5_mirai = absrisk_5) |>
  merge(select(risk_tc, TCode, absrisk_5_tc = absrisk_5), by = "TCode") |>
  merge(risk_cumulus, by = "TCode", all.x = T)

# Create case/control indicator
study.data.fup <- study.data.fup |>
  mutate(
    
    case_control_status = case_when(
      is.finite(time.of.onset) & time.of.onset < (study.exit.age - study.entry.age) ~ 1,
      TRUE ~ 0
    )
    
  )

# Removing participants who die within a year
# NOTE: This is true as only participants left with time.of.onset < 5 are those who died in that window
cat(paste0("Removing ", study.data.fup |> filter((study.exit.age - study.entry.age < 1)) |> nrow(), " participants who die within one year of follow up"))
study.data.fup <- filter(study.data.fup, !(study.exit.age - study.entry.age < 1))
cat(paste0("Number of participants: ", nrow(study.data.fup)))

# Removing participants with any prior breast cancer
# Need to grab age at event (invasive cancer) and whether it was a breast cancer or not
data_bc_prior <- data_cancer %>%
  mutate(
    # Create new variables and recode position 0 to 999
    # so 'no registry' or 'no reported' info is last
    reginfo_clusterino99 = ifelse(Reginfo_Clusterino == 0, 999, Reginfo_Clusterino),
    report_cluster99 = ifelse(Report_Cluster == 0, 999, Report_Cluster),
    
    date_diag = as.Date(diagdate_f, format = "%Y-%m-%d %H:%M:%S"),
    
    # Breast cancer
    breast_cancer = if_else(
      (str_sub(ICDt, 1, 3) == "C50") |
        (str_sub(ICDt, 1, 3) == "174") |
        (str_sub(ICDt, 1, 3) == "D05") |
        (str_sub(ICDt, 1, 4) == "2330"), 1, 0),
    
  ) %>%
  filter(breast_cancer == 1) |>
  arrange(TCode, date_diag, reginfo_clusterino99, report_cluster99) %>%
  group_by(TCode) %>%
  mutate(n_tcode = order(TCode)) %>%
  filter(n_tcode == 1) %>%
  ungroup() |>
  select(TCode, date_diag_all_bc = date_diag)

study.data.fup.bc <- study.data.fup |>
  merge(data_bc_prior, by = "TCode", all.x = T) |>
  filter(case_when(
    is.na(date_diag_all_bc) ~ FALSE,
    TRUE ~ date_diag_all_bc < fupca_start_F
  ))


# Removing participants with ANY prior breast cancer
cat(paste0("Removing ", study.data.fup |> filter(TCode %in% study.data.fup.bc$TCode) |> nrow(), " participants with any prior breast cancer"))
study.data.fup <- filter(study.data.fup, !(TCode %in% study.data.fup.bc$TCode))
cat(paste0("Number of participants: ", nrow(study.data.fup)))

  
# Population summary
table(study.data.fup$case_control_status)
summary(study.data.fup$time.of.onset[study.data.fup$case_control_status == 1])
ggplot(study.data.fup |> filter(case_control_status == 1), aes(x = time.of.onset)) + 
  geom_density() +
  theme_minimal()


# Calculate AUCs
for(risk_score in c("absrisk_5_tc", "absrisk_5_mirai", "Cumulus_Reading")){
  
  auc <- suppressWarnings(auc(study.data.fup$case_control_status, study.data.fup[[risk_score]]))
  ci <- ci(auc)
  
  cat(paste0("AUC for ", risk_score, ": ", round(auc, 5), " (" , paste0(round(ci[-2], 5), collapse = ", "), ")"))
  
}
