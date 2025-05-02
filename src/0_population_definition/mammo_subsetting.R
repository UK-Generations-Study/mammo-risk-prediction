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

# ------------------------- #
# A. Selecting participants
# ------------------------- #

# Selection criteria:
# 1. Mirai mammograms "were taken either on a Selenia Dimensions device (Hologic) or a Lorad Selenia device (Hologic)."
table(data_mammo_images$Manufacturer) # HOLOGIC, Inc., LORAD, Lorad, A Hologic Company
table(data_mammo_images$ManuModelName) # Hologic Selenia, Lorad Selenia, Selenia Dimensions

with(data_mammo_images %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')), table(ManuModelName, Manufacturer,useNA="always"))
with(data_mammo_images %>% filter(ManuModelName %in% c('Hologic Selenia', 'Lorad Selenia', 'Selenia Dimensions')), table(Manufacturer, ManuModelName,useNA="always"))

subset_step1 <- data_mammo_images %>% filter(ManuModelName %in% c('Hologic Selenia', 'Lorad Selenia', 'Selenia Dimensions'), 
                                             Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')) # This drops unspecified or non-Hologic/Lorad manufacturer names to be safe. 

#data_mammo_images %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')) %>% group_by(ManuModelName) %>% summarise(participants=length(unique(TCode.x)))

# 2. "Mirai expects [...] “For Presentation” views of the mammogram"
with(subset_step1, table(ManuModelName, PresentationIntentType))
subset_step2 <- subset_step1 %>% filter(PresentationIntentType == 'FOR PRESENTATION')
with(subset_step2, table(ManuModelName, Manufacturer)) 

# 3. Exclusion of DICOMs for which we have no information on the date the mammogram was taken.
subset_step3 <- subset_step2 %>% filter(StudyDate_m != 'NULL')

# 4. "all four standard views" (L CC, L MLO, R CC, and R MLO)
# Question:
# 1. Can participants have DICOMs with different StudyDate_m's
#    that are from the same mammography study?
# Using StudyDate as a proxy for Study
# table(subset_step2$View_m)
required_views <- c("RCC", "RMLO", "LCC", "LMLO")
subset_step4 <- subset_step3 %>% mutate(StudyDate_m_fmt = dmy(StudyDate_m)) %>%
  group_by(TCode) %>%
  mutate(StudyIndex = dense_rank(StudyDate_m_fmt)) %>%
  ungroup() %>%
  group_by(TCode, StudyIndex) %>%
  filter(all(required_views %in% View_m),
         View_m %in% required_views) %>%
  ungroup()

table(subset_step4$View_m, subset_step4$ViewPosition)

# 5. Implants: Within Mirai paper, in test of generalization the population was "without implants and without prior breast cancer"
table(subset_step4$BreastImplantPresent,useNA='always')
subset_step5 <- subset_step4 %>%
  group_by(TCode, StudyIndex) %>%
  filter(all(BreastImplantPresent == 'NO')) %>%
  ungroup()

# The number of DICOMs we have for each study (some have extra L/R MLO/CC views)
View(subset_step5 %>%
       group_by(TCode, StudyIndex) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))

View(subset_step5 %>%
       group_by(TCode, StudyIndex) %>%
       #filter(n() > 4) %>%
       ungroup())

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
# subset_step5_lateststudy <- subset_step5 %>%
#   group_by(TCode) %>%
#   filter(StudyDate_m_fmt == max(StudyDate_m_fmt, na.rm = TRUE)) %>%
#   ungroup()
# write.csv(subset_step5_lateststudy[,'SOPInstanceUID',drop=F], r"(../../../data/eligible_dicomuids_lateststudy3.csv)", row.names=F)
data_images_dates <- data_mammo_images|>
  filter(SOPInstanceUID %in% subset_step5$SOPInstanceUID) |>
  group_by(SOPInstanceUID) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

subset_step6 <- subset_step5 %>% dplyr::select(-StudyDate_m) |> 
  merge(data_images_dates, by = "SOPInstanceUID") |>
  do(create_analytical_dataset(., years = NA, cancer = "all_breast", fup_start_date = "StudyDate_m", data_cancer = data_cancer))

subset_step6 <- subset_step6 %>%
  dplyr::select(-setdiff(setdiff(colnames(subset_step6), colnames(subset_step5)), c('fupca_end_reason', 'study.exit.age', 'study.entry.age')))

#### -- sAnItY check -- ####

# subset_step6_breast <- subset_step5 %>% dplyr::select(-StudyDate_m) |> 
#   merge(data_images_dates, by = "SOPInstanceUID") |>
#   do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m", data_cancer = data_cancer))
# 
# subset_step6_datediag <- subset_step6 %>% group_by(TCode) %>% summarise(date_diag = unique(date_diag))
# subset_step6_breast_datediag <- subset_step6_breast %>% group_by(TCode) %>% summarise(date_diag = unique(date_diag))
# merged <- subset_step6_breast_datediag %>% left_join(subset_step6_datediag, by='TCode')
# any(merged$date_diag.y < merged$date_diag.x, na.rm=T)
# 
# subset_step6 <- get_earliest_cancer(data_cancer = data_cancer, cancer = 'breast')
# 
# get_earliest_cancer(data_cancer = data_cancer, cancer = 'breast')

#### -- sAnItY check -- ####

# 7. ! patients who did not have at least 1 year of screening follow-up (ie., died)
# study.exit.age - study.entry.age < 1 & fupca_end_reason == 22
subset_step7a <- subset_step6 %>% filter(!(study.exit.age - study.entry.age < 1 & fupca_end_reason == 22))

# 8. For Strategy B: Dropping mammogram studies taken less than 1 year before an invasive/in situ breast cancer cancer diagnosis.
subset_step7b <- subset_step7a %>% left_join(get_earliest_cancer(data_cancer = data_cancer, cancer = 'breast') %>% 
                                             dplyr::select(TCode, date_diag), by ='TCode') %>%
  filter(is.na(date_diag) | time_length(interval(StudyDate_m_fmt, date_diag), "year") >= 1)
# with(subset_step7 %>% left_join(get_earliest_cancer(data_cancer = data_cancer, cancer = 'breast') %>% 
# dplyr::select(TCode, date_diag), by ='TCode') %>% mutate(diff = time_length(interval(StudyDate_m_fmt, date_diag), "year")), hist(diff, breaks=20))
setdiff(subset_step7a$TCode, subset_step7b$TCode) # 162 participants' only mammogram study was within 1 yr prior to diagnosis

# Finally:
# Export unique TCodes
subset_step7a_tcodes <- unique(subset_step7a[,'TCode'])
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
write.csv(subset_step7a_tcodes, r"(../../../data/eligible_tcodes.csv)", row.names=F)

# ------------------------- #
# B. Selecting studies
# ------------------------- #

# How many studies per participant?
subset_step7a %>% group_by(TCode) %>% summarise(Studies = length(unique(StudyIndex)))
subset_step7b %>% group_by(TCode) %>% summarise(Studies = length(unique(StudyIndex)))

# Filtering to studies with at least 4 views
# subset_step5 %>% group_by(TCode, StudyIndex) %>% summarise(DICOMs = n()) # All have at least 4.

# Two subsetting strategies to select one study per participant:
# Subset A: Latest DICOM studies (take the most recent DICOM study)
# Selecting only the latest study
subset_step8a <- subset_step7a %>%
  group_by(TCode) %>%
  filter(StudyDate_m_fmt == max(StudyDate_m_fmt, na.rm = TRUE)) %>%
  ungroup()
subset_step8b <- subset_step7b %>%
  group_by(TCode) %>%
  filter(StudyDate_m_fmt == max(StudyDate_m_fmt, na.rm = TRUE)) %>%
  ungroup()

# # # To sanity check, the different DICOMs in B come from participants that in A had their mammogram study LATER ONLY.
# This is prior to removal of repeated (tcode, view, laterality) combinations
extra_dicoms_to_request_tcodes <- unique(subset_step8b %>% dplyr::filter(SOPInstanceUID %in% 
                                                                           setdiff(subset_step8b$SOPInstanceUID, subset_step8a$SOPInstanceUID))
                                         %>% pull(TCode))
# subset_step8a %>% distinct(TCode,StudyDate_m_fmt) %>% dplyr::select(TCode, StudyDate_m_fmt) %>% 
#   left_join(subset_step8b %>% distinct(TCode,StudyDate_m_fmt, date_diag) %>% dplyr::select(TCode, date_diag, StudyDate_m_fmt), by='TCode') %>%
#   dplyr::filter(TCode %in% extra_dicoms_to_request_tcodes) 

# # The number of DICOMs we have for each study (some have extra L/R MLO/CC views)
# View(subset_step6 %>%
#        group_by(TCode, StudyIndex) %>%
#        summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))
# 
# # Confirming one study selected per participant
# with(subset_step6 %>%
#        group_by(TCode, StudyIndex) %>%
#        summarise(DICOMs = n()) %>% arrange(desc(DICOMs)), !any(duplicated(TCode)))

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
  semi_join(subset_step9b, by = c("TCode", "StudyDate_m_fmt"))
set.seed(42)
subset_step9b_diffstudies <- subset_step8b %>%
  anti_join(
    subset_step9a %>% dplyr::select(TCode, StudyDate_m_fmt),
    by = c("TCode", "StudyDate_m_fmt")
  ) %>%
  group_by(TCode, View_m) %>%
  slice_sample(n = 1) %>%
  ungroup()
subset_step9b <- bind_rows(subset_step9b_samestudies, subset_step9b_diffstudies)

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
# # Sanity checking this
# participants_with_prediag_mammo <- subset_step7a %>% left_join(get_earliest_cancer(data_cancer = data_cancer, cancer = 'breast') %>% 
#                               dplyr::select(TCode, date_diag), by ='TCode') %>%
#   filter(!is.na(date_diag) & time_length(interval(StudyDate_m_fmt, date_diag), "year") < 1) %>% pull(TCode) # Correct
# 
# View(subset_step9a %>% dplyr::distinct(TCode, StudyDate_m_fmt) %>% inner_join(subset_step9b_diffstudies, by='TCode'))
# View(subset_step9a %>% dplyr::distinct(TCode, StudyDate_m_fmt) %>% inner_join(subset_step9b_diffstudies %>% dplyr::distinct(TCode, StudyDate_m_fmt, date_diag), by='TCode'))

# DICOMs per TCode
View(subset_step9a %>%
       group_by(TCode) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))
View(subset_step9b %>%
       group_by(TCode) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))

# Exporting list of DICOM identifiers
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
write.csv(subset_step7[,'SOPInstanceUID',drop=F], r"(../../../data/eligible_dicomuids.csv)", row.names=F)
