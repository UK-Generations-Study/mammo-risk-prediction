library(dplyr)

###############
## Load data ##
###############

# Load complete DICOM metadata
data_all_mammo_metadata_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_all_mammo_metadata <- read.csv(data_mammo_images_fn, stringsAsFactors = FALSE)

# Load filenames of exported DICOMs (following subset selection)
data_available_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms)"
data_available_mammo_images_fns <- data.frame(filename = list.files(data_available_mammo_images_dn))
data_available_mammo_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(gsub('_', '.', data_available_mammo_images_fns$filename))
data_available_mammo_images_fns <- data_available_mammo_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')

# Partipants not in the exported data (8 DICOMs, due to voluntary exclusion)
eligible_ids <- read.csv(r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\eligible_dicomuids.csv)")
data_all_mammo_metadata %>% dplyr::filter(SOPInstanceUID %in% eligible_ids[!eligible_ids$SOPInstanceUID %in% data_available_mammo_images_fns$SOPInstanceUID, 'SOPInstanceUID']) %>% pull(TCode) %>% unique()

# Any participant that doesn't have 4 DICOMs? -> All have 4 DICOMs.
(data_available_mammo_images_fns %>% group_by(TCode) %>% summarize(count = n()) %>% dplyr::filter(count != 4))

####################
## Build manifest ##
####################

data_available_mammo_png_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_png\)"

# Build manifest file for Mirai
mirai_manifest <- data.frame(patient_id = data_available_mammo_images_fns$TCode, exam_id = 0, 
                             laterality = data_available_mammo_images_fns$ImageLaterality,
                             view = data_available_mammo_images_fns$ViewPosition,
                             file_path = paste0(data_available_mammo_png_images_dn, data_available_mammo_images_fns$filename, '.png'))

# Setting these values to constant, as only interested in risk scores for now
mirai_manifest$years_to_cancer <- 0
mirai_manifest$years_to_last_followup <- 0

# All are 'test' set
mirai_manifest$split_group <- 'test'

# Export manifest
mirai_manifest_output_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\mirai_manifest.csv)"
write.csv(mirai_manifest, mirai_manifest_output_dn)