library(dplyr)
library(ggplot2)

data_mammo_images_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_mammo_images <- read.csv(data_mammo_images_fn, stringsAsFactors = FALSE)

data_mammo_cumulus_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoCumulus_v1.csv)"
data_mammo_cumulus <- read.csv(data_mammo_cumulus_fn, stringsAsFactors = FALSE)

data_mammo_set_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoSet_v1.csv)"
data_mammo_set <- read.csv(data_mammo_set_fn, stringsAsFactors = FALSE)

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

# 3. "all four standard views" (L CC, L MLO, R CC, and R MLO)
# Question:
# 1. Can participants have DICOMs with different StudyDate_m's
#    that are from the same mammography study?
# Using StudyDate as a proxy for Study
# table(subset_step2$View_m)
required_views <- c("RCC", "RMLO", "LCC", "LMLO")
subset_step3 <- subset_step2 %>%
  group_by(TCode) %>%
  mutate(StudyIndex = dense_rank(StudyDate_m)) %>%
  ungroup() %>%
  group_by(TCode, StudyIndex) %>%
  filter(all(required_views %in% View_m),
         View_m %in% required_views) %>%
  ungroup()

table(subset_step3$View_m, subset_step3$ViewPosition)

# 4. Implants: Within Mirai paper, in test of generalization the population was "without implants and without prior breast cancer"
table(subset_step3$BreastImplantPresent,useNA='always')
subset_step4 <- subset_step3 %>%
  filter(BreastImplantPresent == 'NO')

# The number of DICOMs we have for each study (some have extra L/R MLO/CC views)
View(subset_step4 %>%
       group_by(TCode, StudyIndex) %>%
       summarise(DICOMs = n()) %>% arrange(desc(DICOMs)))

View(subset_step4 %>%
       group_by(TCode, StudyIndex) %>%
       filter(n() > 4) %>%
       ungroup())

# Sanity check
sanity_check <- subset_step4 %>% left_join(data_mammo_set %>% dplyr::select('SOPInstanceUID', 'ImageType'), by = c('SOPInstanceUID'))
sanity_check_digitised <- sanity_check %>% filter(ImageType.y == 'Analogue_Digitised') # Labelled (potentially incorrectly) as digitised
table(sanity_check_digitised$SOPClassUID)
table(sanity_check_digitised$SCDManu)
table(sanity_check_digitised$SCDManuModelName)
table(sanity_check_digitised$DetectorType)
# All in fact digital.

# Export
subset_step4_tcodes <- unique(subset_step4[,'TCode'])
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
write.csv(subset_step4_tcodes, r"(../../../data/eligible_tcodes.csv)")

# 5. ! patients who did not have at least 1 year of screening follow-up
# Subsetting performed in a separate script.

# 6. ! who were diagnosed with other cancers such as sarcomas of the breast
# Subsetting performed in a separate script.

# 7. prior history of breast cancer ("to enable fair comparison against the Tyrer-Cuzick model")
# Subsetting performed in a separate script.


