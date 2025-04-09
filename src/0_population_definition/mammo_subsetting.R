library(dplyr)
library(ggplot2)
library(lubridate)

data_mammo_images_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_mammo_images <- read.csv(data_mammo_images_fn, stringsAsFactors = FALSE)

data_mammo_cumulus_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoCumulus_v1.csv)"
data_mammo_cumulus <- read.csv(data_mammo_cumulus_fn, stringsAsFactors = FALSE)

data_mammo_set_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoSet_v1.csv)"
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

# Export unique TCodes
subset_step5_tcodes <- unique(subset_step5[,'TCode'])
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
write.csv(subset_step5_tcodes, r"(../../../data/eligible_tcodes.csv)", row.names=F)

subset_step5_tcodes <- read.csv(r"(../../../data/eligible_tcodes.csv)")

# 6. ! patients who did not have at least 1 year of screening follow-up
# Subsetting performed in a separate script.

# 7. ! who were diagnosed with other cancers such as sarcomas of the breast
# Subsetting performed in a separate script.

# 8. prior history of breast cancer ("to enable fair comparison against the Tyrer-Cuzick model")
# Subsetting performed in a separate script.


# ------------------------- #
# B. Selecting studies
# ------------------------- #

# How many studies per participant?
subset_step5 %>% group_by(TCode) %>% summarise(Studies = length(unique(StudyIndex)))

# Filtering to studies with at least 4 views

# Selecting only the latest study
subset_step6 <- subset_step5 %>%
  group_by(TCode) %>%
  filter(StudyDate_m_fmt == max(StudyDate_m_fmt, na.rm = TRUE)) %>%
  ungroup()

# The number of DICOMs we have for each study (some have extra L/R MLO/CC views)
View(subset_step6 %>%
       group_by(TCode, StudyIndex) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))

# Confirming one study selected per participant
with(subset_step6 %>%
       group_by(TCode, StudyIndex) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)), !any(duplicated(TCode)))

# ------------------------- #
# C. Selecting DICOMs
# ------------------------- #

# When multiple of the same view exists within a study, select one (at random)
set.seed(42)

subset_step7 <- subset_step6 %>%
  group_by(TCode, View_m) %>%
  slice_sample(n = 1) %>% 
  ungroup()

# DICOMs per TCode
View(subset_step7 %>%
       group_by(TCode) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))

# Exporting list of DICOM identifiers
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
write.csv(subset_step7[,'SOPInstanceUID',drop=F], r"(../../../data/eligible_dicomuids.csv)", row.names=F)
