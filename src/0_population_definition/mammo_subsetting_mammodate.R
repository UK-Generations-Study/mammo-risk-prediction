library(dplyr)
library(readr)
library(ggplot2)
library(sqldf)
library(lubridate)
library(crosstable)
library(stringr)
library(Hmisc)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source('../helper_functions/data_processing.R')

data_mammo_images_fn <- r"(\\rds\Data\DGE\DUDGE\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_mammo_images <- read.csv(data_mammo_images_fn, stringsAsFactors = FALSE)

data_mammo_cumulus_fn <- r"(\\rds\Data\DGE\DUDGE\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoCumulus_v1.csv)"
data_mammo_cumulus <- read.csv(data_mammo_cumulus_fn, stringsAsFactors = FALSE)

data_mammo_set_fn <- r"(\\rds\Data\DGE\DUDGE\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoSet_v1.csv)"
data_mammo_set <- read.csv(data_mammo_set_fn, stringsAsFactors = FALSE)

# Function for counting participants for CONSORT diagram
count_population <- function(data){
  
  data_subset <- data_mammo_set |>
    filter(TCode %in% data$TCode) |>
    select(TCode, CaseControlRequestStatus) |>
    distinct() |>
    xtabs(formula = ~ CaseControlRequestStatus)
  
  return(data_subset)
  
}

# ------------------------- #
# A. Selecting participants
# ------------------------- #

# Selection criteria:
# 1. Mirai mammograms "were taken either on a Selenia Dimensions device (Hologic) or a Lorad Selenia device (Hologic)."
table(data_mammo_images$Manufacturer) # HOLOGIC, Inc., LORAD, Lorad, A Hologic Company
table(data_mammo_images$ManuModelName) # Hologic Selenia, Lorad Selenia, Selenia Dimensions

with(data_mammo_images %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')), table(ManuModelName, Manufacturer,useNA="always"))
with(data_mammo_images %>% filter(ManuModelName %in% c('Hologic Selenia', 'Lorad Selenia', 'Selenia Dimensions')), table(Manufacturer, ManuModelName,useNA="always"))

count_population(data_mammo_images)

subset_step1 <- data_mammo_images %>% filter(ManuModelName %in% c('Hologic Selenia', 'Lorad Selenia', 'Selenia Dimensions'), 
                                             Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')) # This drops unspecified or non-Hologic/Lorad manufacturer names to be safe. 

count_population(subset_step1)

# 2. "Mirai expects [...] “For Presentation” views of the mammogram"
with(subset_step1, table(ManuModelName, PresentationIntentType))
subset_step2 <- subset_step1 %>% filter(PresentationIntentType == 'FOR PRESENTATION')
with(subset_step2, table(ManuModelName, Manufacturer)) 

count_population(subset_step2)


# 3. Exclusion of DICOMs for which we have no information on the date the mammogram was taken.
# Also filtering the mammoset to exclude those collected for USD Study Only
subset_step3 <- subset_step2 %>% left_join(data_mammo_set %>% filter(Comments != "USD Study Only") |> dplyr::select(SOPInstanceUID, MammoDate, YearOfMammo), by = 'SOPInstanceUID') %>%
  filter(MammoDate != 'NULL')

count_population(subset_step3)


# 4. "all four standard views" (L CC, L MLO, R CC, and R MLO)
# Question:
# 1. Can participants have DICOMs with different StudyDate_m's
#    that are from the same mammography study?
# Using StudyDate as a proxy for Study
# table(subset_step2$View_m)
required_views <- c("RCC", "RMLO", "LCC", "LMLO")
subset_step4 <- subset_step3 %>% mutate(MammoDate = dmy(MammoDate)) %>%
  group_by(TCode) %>%
  mutate(StudyIndex = dense_rank(MammoDate)) %>%
  ungroup() %>%
  group_by(TCode, StudyIndex) %>%
  filter(all(required_views %in% View_m),
         View_m %in% required_views) %>%
  ungroup()

count_population(subset_step4)

table(subset_step4$View_m, subset_step4$ViewPosition)

# 5. Implants: Within Mirai paper, in test of generalization the population was "without implants and without prior breast cancer"
table(subset_step4$BreastImplantPresent,useNA='always')
subset_step5 <- subset_step4 %>%
  group_by(TCode, StudyIndex) %>%
  filter(all(BreastImplantPresent == 'NO')) %>%
  ungroup()

count_population(subset_step5)

# Sanity check
sanity_check <- subset_step5 %>% left_join(data_mammo_set %>% dplyr::select('SOPInstanceUID', 'ImageType'), by = c('SOPInstanceUID'))
sanity_check_digitised <- sanity_check %>% filter(ImageType.y == 'Analogue_Digitised') # Labelled (potentially incorrectly) as digitised
table(sanity_check_digitised$SOPClassUID)
table(sanity_check_digitised$SCDManu)
table(sanity_check_digitised$SCDManuModelName)
table(sanity_check_digitised$DetectorType)
# All in fact digital.

# 6. ! prior history of breast cancer (including sarcomas of the breast)   ("to enable fair comparison against the Tyrer-Cuzick model")
data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv")

data_images_dates <- data_mammo_set|>
  filter(SOPInstanceUID %in% subset_step5$SOPInstanceUID) |>
  group_by(SOPInstanceUID) |>
  summarise(MammoDate = as.Date(unique(MammoDate), format = "%d/%m/%Y"),
            TCode = unique(TCode)) |>
  ungroup()

subset_step6 <- subset_step5 |> 
  select(-TCode) |>
  merge(data_images_dates, by = c("SOPInstanceUID", "MammoDate")) |>
  do(create_analytical_dataset(., years = NA, cancer = "all_breast", fup_start_date = "MammoDate", data_cancer = data_cancer))

subset_step6 <- subset_step6 %>%
  dplyr::select(-setdiff(setdiff(colnames(subset_step6), colnames(subset_step5)), c('fupca_end_reason', 'study.exit.age', 'study.entry.age', 'time.of.onset', 'fupca_start_F'))) |>
  rename(MammoDate = fupca_start_F)

count_population(subset_step6)

# 7. ! patients who did not have at least 1 year of screening follow-up (ie., died)
subset_step7a <- subset_step6 %>% filter(!(study.exit.age - study.entry.age < 1 & fupca_end_reason == 22))

count_population(subset_step7a)


# 8. For Strategy B: Dropping mammogram studies taken less than 1 year before an invasive/in situ breast cancer cancer diagnosis.
subset_step7b <- subset_step7a %>% left_join(get_earliest_cancer(data_cancer = data_cancer, cancer = 'all_breast') %>%
                                             dplyr::select(TCode, date_diag), by ='TCode') %>%
  filter(is.na(date_diag) | time_length(interval(MammoDate, date_diag), "year") >= 1)

count_population(subset_step7b)

# ------------------------- #
# B. Selecting studies
# ------------------------- #

# How many studies per participant?
subset_step7a %>% group_by(TCode) %>% summarise(Studies = length(unique(StudyIndex)))
subset_step7b %>% group_by(TCode) %>% summarise(Studies = length(unique(StudyIndex)))

# Get studies with Cumulus measurements
cumulus_studies <- data_mammo_cumulus |>
  filter(Reader_ID != "JW") |>
  filter(SOPInstanceUID %in% subset_step7b$SOPInstanceUID) |>
  select(TCode, SOPInstanceUID) |>
  merge(select(subset_step7b, SOPInstanceUID, study.entry.age), by = "SOPInstanceUID", all.x = T) |>
  select(TCode, cumulus.age = study.entry.age) |>
  distinct()

# Two subsetting strategies to select one study per participant:
# Subset A: Latest DICOM studies (take the most recent DICOM study)
# Selecting only the latest study
subset_step8a <- subset_step7a %>%
  group_by(TCode) %>%
  filter(MammoDate == max(MammoDate, na.rm = TRUE)) %>%
  ungroup()
subset_step8b <- subset_step7b %>%
  group_by(TCode) %>%
  filter(MammoDate == max(MammoDate, na.rm = TRUE)) %>%
  ungroup()

# Derive subset_step8b using cumulus measurements
subset_step8c <- subset_step7b |>
  mutate(cumulus_measurement = F)
for(t in unique(subset_step7b$TCode)){

  cumulus_ages <- cumulus_studies |> filter(TCode == t) |> select(cumulus.age) |> unique()

  subset_step8c <- subset_step8c |>
    mutate(cumulus_measurement = case_when(
      TCode != t ~ cumulus_measurement,
      TRUE ~ study.entry.age %in% cumulus_ages
    ))

}

subset_step8c <- subset_step8c |>
  group_by(TCode) |>
  filter(
    case_when(
      sum(cumulus_measurement) > 0 ~ cumulus_measurement,
      TRUE ~ TRUE
    )
  ) |>
  filter(MammoDate == max(MammoDate, na.rm = TRUE)) |>
  ungroup()

# Subset B: Drop all studies within one year preceding earliest breast cancer diagnosis 

# ------------------------- #
# C. Selecting DICOMs
# ------------------------- #

# When multiple of the same view exists within a study, select one (at random)
# Strategy A
set.seed(42)
subset_step9a <- subset_step8a %>%
  group_by(TCode, View_m) %>%
  slice_sample(n = 1) %>% 
  ungroup()
# Strategy B (for the studies that were the same between A and B, use the same DICOM selection as A)
subset_step9b_samestudies <- subset_step9a %>% 
  semi_join(subset_step8b, by = c("TCode", "MammoDate"))
set.seed(42)
subset_step9b_diffstudies <- subset_step8b %>%
  anti_join(
    subset_step9a %>% dplyr::select(TCode, MammoDate),
    by = c("TCode", "MammoDate")
  ) %>%
  group_by(TCode, View_m) %>%
  slice_sample(n = 1) %>%
  ungroup()
subset_step9b <- bind_rows(subset_step9b_samestudies, subset_step9b_diffstudies)

# Strategy C (for the studies that were the same between B and C, use the same DICOM selection as B)
subset_step9c_samestudies <- subset_step9b %>% 
  semi_join(subset_step8c, by = c("TCode", "MammoDate"))
set.seed(42)
subset_step9c_diffstudies <- subset_step8c %>%
  anti_join(
    subset_step9b %>% dplyr::select(TCode, MammoDate),
    by = c("TCode", "MammoDate")
  ) %>%
  group_by(TCode, View_m) %>%
  slice_sample(n = 1) %>%
  ungroup()
subset_step9c <- bind_rows(subset_step9c_samestudies, subset_step9c_diffstudies)

# Check how many participants in strategy B have a cumulus measurement
n_participants <- length(unique(subset_step9b$TCode))
n_cumulus_b <- 0
for(t in unique(subset_step9b$TCode)){
  
  tcodes_age <- subset_step9b |> filter(TCode == t) |> select(study.entry.age) |> unique()
  cumulus_age <- cumulus_studies |> filter(TCode == t) |> select(cumulus.age) |> unique()
  
  if(tcodes_age %in% cumulus_age){
    n_cumulus_b <- n_cumulus_b + 1
  }
  
}

n_cumulus_c <- 0
for(t in unique(subset_step9c$TCode)){
  
  tcodes_age <- subset_step9c |> filter(TCode == t) |> select(study.entry.age) |> unique()
  cumulus_age <- cumulus_studies |> filter(TCode == t) |> select(cumulus.age) |> unique()
  
  if(tcodes_age %in% cumulus_age){
    n_cumulus_c <- n_cumulus_c + 1
  }
  
}

# Participants that did not have a previous study 1+ yr before diagnosis
setdiff(subset_step9a$TCode, subset_step9b$TCode) # TCodes
length(setdiff(subset_step9a$TCode, subset_step9b$TCode)) / length(unique(subset_step9a$TCode)) # Fraction of (A) with <1yr mammo that were dropped in (B)

# Participants that did have a previous study 1+ yr before diagnosis
unique(subset_step9b_diffstudies$TCode)  # TCodes
length(unique(subset_step9b_diffstudies$TCode)) / length(unique(subset_step9a$TCode)) # Fraction of (A) with <1yr mammo that were kept in (B) (ie., had a >=1yr mammo)

# Participants whose latest mammogram was within 1 yr before diagnosis (subset of (A))
length(setdiff(subset_step9a$TCode, subset_step9b$TCode)) + length(unique(subset_step9b_diffstudies$TCode)) # Number
(length(setdiff(subset_step9a$TCode, subset_step9b$TCode)) + length(unique(subset_step9b_diffstudies$TCode))) /
  length(unique(subset_step9a$TCode))

# Exporting list of DICOM identifiers
# setwd(dirname(rstudioapi::getSourceEditorContext()$path))
# write.csv(subset_step9a[,'SOPInstanceUID',drop=F], r"(../../../data/eligible_dicomuids_mammodate_strategyA.csv)", row.names=F)
# write.csv(subset_step9b[,'SOPInstanceUID',drop=F], r"(../../../data/eligible_dicomuids_mammodate_strategyB.csv)", row.names=F)
# write.csv(subset_step9c[,'SOPInstanceUID',drop=F], "../../../../../data/case_control/population/eligible_dicomuids_mammodate_strategyB_cumulus_20260812.csv", row.names=F)
