library(dplyr)

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")

# Defining population: Eligible DICOM UIDS
eligible_dicom <- list()
eligible_dicom[["A"]] <- read.csv("../../../data/eligible_dicomuids_strategyA.csv")
eligible_dicom[["B"]] <- read.csv("../../../data/eligible_dicomuids_strategyB.csv")

# Defining population: determine follow-up start date (date of mammogram)
data_images_dates_strategyA <- data_images |>
  filter(SOPInstanceUID %in% eligible_dicom[["A"]]$SOPInstanceUID) |>
  group_by(TCode) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

data_images_dates_strategyB <- data_images |>
  filter(SOPInstanceUID %in% eligible_dicom[["B"]]$SOPInstanceUID) |>
  group_by(TCode) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

# Risk scores: Mirai
load_mirai_score <- function(score_csv) {
  read.csv(score_csv) %>%
    rename(TCode = patient_exam_id, mirai_score_5y = X5_year_risk) %>% 
    mutate(TCode = gsub("([A-Za-z\\d]+)(\t0)", '\\1', TCode, perl=T)) %>%
    dplyr::select(TCode, mirai_score_5y)
}
risk_mirai_strategyA <- load_mirai_score("../../../output/mirai_scores_strategyA.csv")
risk_mirai_strategyB <- load_mirai_score("../../../output/mirai_scores_strategyB.csv")

# Risk scores: Cumulus
data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")
cumulus_scores_strategyA <- data_cumulus |>
  filter(SOPInstanceUID %in% eligible_dicom[["A"]]$SOPInstanceUID) |>
  filter(Reader_ID != "JW") |>
  group_by(TCode) |>
  summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))
cumulus_scores_strategyB <- data_cumulus |>
  filter(SOPInstanceUID %in% eligible_dicom[["B"]]$SOPInstanceUID) |>
  filter(Reader_ID != "JW") |>
  group_by(TCode) |>
  summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))

# Merge time-to-event, risk factors, and risk scores
study.data.strategyA <- data_images_dates_strategyA |>
  do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m")) |>
  merge(risk_mirai_strategyA, by='TCode') |> 
  merge(cumulus_scores_strategyA, by='TCode', all.x=T)

study.data.strategyB <- data_images_dates_strategyB |>
  do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m")) |>
  merge(risk_mirai_strategyB, by='TCode') |> 
  merge(cumulus_scores_strategyB, by='TCode', all.x=T)

# Correlation with age at mammogram
plot(study.data.strategyB$study.entry.age, study.data.strategyB$mirai_score_5y)
cor(study.data.strategyB$study.entry.age, study.data.strategyB$mirai_score_5y)

# Correlation with Cumulus scores
plot(study.data.strategyB$cumulus_reading, study.data.strategyB$mirai_score_5y)
with(study.data.strategyB %>% filter(!is.na(cumulus_reading)), cor(cumulus_reading, mirai_score_5y))