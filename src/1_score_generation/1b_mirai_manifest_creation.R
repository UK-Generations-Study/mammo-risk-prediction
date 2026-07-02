library(dplyr)

# To execute aftrer DICOM -> PNG conversion

###############
## Load data ##
###############

# ----- Sanity check available DICOM images ----- #

# Load complete DICOM metadata
data_all_mammo_metadata_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_all_mammo_metadata <- read.csv(data_all_mammo_metadata_fn, stringsAsFactors = FALSE)

# Load filenames of exported DICOMs (following subset selection)
data_available_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\mirai\data\dicoms_202508)"
data_available_mammo_images_fns <- data.frame(filename = list.files(data_available_mammo_images_dn))
data_available_mammo_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(gsub('_', '.', data_available_mammo_images_fns$filename))
data_available_mammo_images_fns <- data_available_mammo_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')

# Partipants not in the exported data
#eligible_ids_strategyA <- read.csv(r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\eligible_dicomuids_strategyA.csv)")
eligible_ids_strategyB <- read.csv(r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\mirai\data\eligible_dicomuids_mammodate_strategyB_cumulus.csv)")
#eligible_ids <- rbind(eligible_ids_strategyA, eligible_ids_strategyB)
eligible_ids <- eligible_ids_strategyB
#data_all_mammo_metadata %>% dplyr::filter(SOPInstanceUID %in% eligible_ids_strategyA[!eligible_ids_strategyA$SOPInstanceUID %in% data_available_mammo_images_fns$SOPInstanceUID, 'SOPInstanceUID']) %>% pull(TCode) %>% unique()
data_all_mammo_metadata %>% dplyr::filter(SOPInstanceUID %in% eligible_ids_strategyB[!eligible_ids_strategyB$SOPInstanceUID %in% data_available_mammo_images_fns$SOPInstanceUID, 'SOPInstanceUID']) %>% pull(TCode) %>% unique()

# Any participant that doesn't have at least 4 DICOMs? -> All have 4+ DICOMs.
(data_available_mammo_images_fns %>% group_by(TCode) %>% dplyr::summarize(count = n()) %>% dplyr::filter(count < 4))

# ----- Sanity check converted DICOM images ----- #

# Load filenames of converted DICOMs
data_available_mammo_png_images_dn <- r"(C:\Users\dadams\DocumentsUnsynced\Projects\mammograms\_DATA\dicoms_202508_png)"
data_available_mammo_png_images_fns <- data.frame(filename = list.files(data_available_mammo_png_images_dn))
data_available_mammo_png_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(tools::file_path_sans_ext(gsub('_', '.', data_available_mammo_png_images_fns$filename)))
data_available_mammo_png_images_fns <- data_available_mammo_png_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')

# Filtering the files to those in the eligible dicom UIDs csv
#data_available_mammo_png_images_fns_strategyA <- data_available_mammo_png_images_fns %>% filter(SOPInstanceUID %in% eligible_ids_strategyA$SOPInstanceUID)
data_available_mammo_png_images_fns_strategyB <- data_available_mammo_png_images_fns %>% filter(SOPInstanceUID %in% eligible_ids_strategyB$SOPInstanceUID)

# Exported DICOMs not in converted PNGs (corrupted, unopenable)
unconverted_dicoms <- data_available_mammo_images_fns %>% anti_join(data_available_mammo_png_images_fns, by = 'SOPInstanceUID')

# # Copying these to a separate directory
# data_unconverted_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_latest_round_unconverted)"
# file.copy(from=paste0(data_available_mammo_images_dn, r'(\)', unconverted_dicoms$filename), to=paste0(data_unconverted_mammo_images_dn, r'(\)', unconverted_dicoms$filename), 
#           overwrite = TRUE, recursive = FALSE, 
#           copy.mode = TRUE)
# 
# ## [ Reconvert failures using latest version of dcmtk ] ##
# 
# # Load filenames of additional round of DICOM conversion
# data_available_reconverted_mammo_png_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_unconverted_png)"
# data_available_reconverted_mammo_png_images_fns <- data.frame(filename = list.files(data_available_reconverted_mammo_png_images_dn))
# data_available_reconverted_mammo_png_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(tools::file_path_sans_ext(gsub('_', '.', data_available_reconverted_mammo_png_images_fns$filename)))
# data_available_reconverted_mammo_png_images_fns <- data_available_reconverted_mammo_png_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')
# 
# # New dataframe of all successfully converted (from original conversion + new dcmtk conversion)
# data_converted_mammo_png_images_fns <- rbind(data_available_mammo_png_images_fns, data_available_reconverted_mammo_png_images_fns)
# data_converted_mammo_png_images_fns <- data_converted_mammo_png_images_fns %>% filter(filename != 'Thumbs.db')
# 
# # Exported DICOMs not in converted PNGs (original conversion + new dcmtk conversion)
# unconverted_dicoms <- data_available_mammo_images_fns %>% anti_join(data_converted_mammo_png_images_fns, by = 'SOPInstanceUID')
# 
# # Copying these to a separate directory
# data_unconverted_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_latest_round_unconverted_round2)"
# file.copy(from=paste0(data_available_mammo_images_dn, r'(\)', unconverted_dicoms$filename), to=paste0(data_unconverted_mammo_images_dn, r'(\)', unconverted_dicoms$filename), 
#           overwrite = TRUE, recursive = FALSE, 
#           copy.mode = TRUE) # These 12 DICOMs belonging to 3 participants turned out to be corrupted DICOMs.



# Completing incomplete TCode studies with previously extracted images.
incompl_tcodes <- data_available_mammo_png_images_fns %>% group_by(TCode) %>% summarise(n = n()) %>% filter(n != 4) %>% pull(TCode)
corresp_uids <- data_all_mammo_metadata %>% filter(TCode %in% incompl_tcodes, SOPInstanceUID %in% eligible_ids$SOPInstanceUID, !SOPInstanceUID %in% data_available_mammo_png_images_fns$SOPInstanceUID) %>%
  pull(SOPInstanceUID)
prev_images_path <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_png)"
prev_images_fns <- data.frame(filename = list.files(prev_images_path))
prev_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(tools::file_path_sans_ext(gsub('_', '.', prev_images_fns$filename)))
corresp_images <- prev_images_fns %>% filter(SOPInstanceUID %in% corresp_uids)
file.copy(from=paste0(prev_images_path, r'(\)', corresp_images$filename), to=paste0(data_available_mammo_png_images_dn, r'(\)', corresp_images$filename),
          overwrite = TRUE, recursive = FALSE,
          copy.mode = TRUE) # These 12 DICOMs belonging to 3 participants turned out to be corrupted DICOMs.
data_available_mammo_png_images_fns <- bind_rows(data_available_mammo_png_images_fns, corresp_images %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID'))

####################
## Build manifest ##
####################

data_available_mammo_png_images_dn <- r"(/data/dicoms_202508_png/)"
#data_available_mammo_png_images_dn <- "C:/Users/dadams/DocumentsUnsynced/Projects/mammograms/_DATA/dicoms_202508_png/"

# # Build manifest file for Mirai
# mirai_manifest_strategyA <- data.frame(patient_id = data_available_mammo_png_images_fns_strategyA$TCode, exam_id = 0, 
#                              laterality = data_available_mammo_png_images_fns_strategyA$ImageLaterality,
#                              view = data_available_mammo_png_images_fns_strategyA$ViewPosition,
#                              file_path = paste0(data_available_mammo_png_images_dn, data_available_mammo_png_images_fns_strategyA$filename))
# 
# # Setting these values to constant, as only interested in risk scores for now
# mirai_manifest_strategyA$years_to_cancer <- 0
# mirai_manifest_strategyA$years_to_last_followup <- 0
# mirai_manifest_strategyA$split_group <- 'test' # All are 'test' set

# Build manifest file for Mirai
mirai_manifest_strategyB <- data.frame(patient_id = data_available_mammo_png_images_fns$TCode, exam_id = 0, 
                               laterality = data_available_mammo_png_images_fns$ImageLaterality,
                               view = data_available_mammo_png_images_fns$ViewPosition,
                               file_path = paste0(data_available_mammo_png_images_dn, data_available_mammo_png_images_fns$filename))

# Setting these values to constant, as only interested in risk scores for now
mirai_manifest_strategyB$years_to_cancer <- 0
mirai_manifest_strategyB$years_to_last_followup <- 0
mirai_manifest_strategyB$split_group <- 'test' # All are 'test' set

#mirai_manifest_strategyA <- mirai_manifest_strategyA %>% arrange(patient_id, view, laterality)
mirai_manifest_strategyB <- mirai_manifest_strategyB %>% arrange(patient_id, view, laterality)

# Export manifest
#mirai_manifest_output_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\mirai_manifest_strategyA.csv)"
#write.csv(mirai_manifest_strategyA, mirai_manifest_output_dn, row.names=F)
#mirai_manifest_output_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\mirai_manifest_strategyB.csv)"
mirai_manifest_output_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\mirai\data\mirai_manifests\mirai_manifest_202508.csv)"
write.csv(mirai_manifest_strategyB, mirai_manifest_output_dn, row.names=F)

############################
## Mirai score generation ##
############################

# ***** #

# ###########################
# ## Checking completeness ##
# ###########################
# 
# # data_available_mammo_png_images_fns_strategyA
# # data_available_mammo_png_images_fns_strategyB
# 
# risk_scores_strategyA <- read.csv('../../../output/mirai_scores_strategyA.csv')
# risk_scores_strategyB <- read.csv('../../../output/mirai_scores_strategyB.csv')
# 
# length(unique(data_available_mammo_png_images_fns_strategyA$TCode))
# length(unique(data_available_mammo_png_images_fns_strategyB$TCode))
# 
# nrow(risk_scores_strategyA)
# nrow(risk_scores_strategyB)
# 
# data_available_mammo_png_images_fns_strategyA |> filter(!TCode %in% gsub("([A-Za-z\\d]+)(\t0)", '\\1', risk_scores_strategyA$patient_exam_id,perl=T)) |> pull(TCode) |> unique()
# data_available_mammo_png_images_fns_strategyB |> filter(!TCode %in% gsub("([A-Za-z\\d]+)(\t0)", '\\1', risk_scores_strategyB$patient_exam_id,perl=T)) |> pull(TCode) |> unique()
