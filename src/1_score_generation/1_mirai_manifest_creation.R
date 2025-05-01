library(dplyr)

# To execute aftrer DICOM -> PNG conversion

###############
## Load data ##
###############

# ----- Sanity check available DICOM images ----- #

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

# ----- Sanity check converted DICOM images ----- #

# Load filenames of converted DICOMs
data_available_mammo_png_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_png)"
data_available_mammo_png_images_fns <- data.frame(filename = list.files(data_available_mammo_png_images_dn))
data_available_mammo_png_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(tools::file_path_sans_ext(gsub('_', '.', data_available_mammo_png_images_fns$filename)))
data_available_mammo_png_images_fns <- data_available_mammo_png_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')

# Exported DICOMs not in converted PNGs
unconverted_dicoms <- data_available_mammo_images_fns %>% anti_join(data_available_mammo_png_images_fns, by = 'SOPInstanceUID')

# Copying these to a separate directory
data_unconverted_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_unconverted)"
file.copy(from=paste0(data_available_mammo_images_dn, r'(\)', unconverted_dicoms$filename), to=paste0(data_unconverted_mammo_images_dn, r'(\)', unconverted_dicoms$filename), 
          overwrite = TRUE, recursive = FALSE, 
          copy.mode = TRUE)

## [ Reconvert failures using latest version of dcmtk ] ##

# Load filenames of additional round of DICOM conversion
data_available_reconverted_mammo_png_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_unconverted_png)"
data_available_reconverted_mammo_png_images_fns <- data.frame(filename = list.files(data_available_reconverted_mammo_png_images_dn))
data_available_reconverted_mammo_png_images_fns$SOPInstanceUID <- tools::file_path_sans_ext(tools::file_path_sans_ext(gsub('_', '.', data_available_reconverted_mammo_png_images_fns$filename)))
data_available_reconverted_mammo_png_images_fns <- data_available_reconverted_mammo_png_images_fns %>% left_join(data_all_mammo_metadata, by='SOPInstanceUID')

# New dataframe of all successfully converted (from original conversion + new dcmtk conversion)
data_converted_mammo_png_images_fns <- rbind(data_available_mammo_png_images_fns, data_available_reconverted_mammo_png_images_fns)

# Exported DICOMs not in converted PNGs (original conversion + new dcmtk conversion)
unconverted_dicoms <- data_available_mammo_images_fns %>% anti_join(data_converted_mammo_png_images_fns, by = 'SOPInstanceUID')

# Copying these to a separate directory
data_unconverted_mammo_images_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\dicoms_unconverted_round2)"
file.copy(from=paste0(data_available_mammo_images_dn, r'(\)', unconverted_dicoms$filename), to=paste0(data_unconverted_mammo_images_dn, r'(\)', unconverted_dicoms$filename), 
          overwrite = TRUE, recursive = FALSE, 
          copy.mode = TRUE) # These 12 DICOMs belonging to 3 participants turned out to be corrupted DICOMs.




####################
## Build manifest ##
####################

data_available_mammo_png_images_dn <- r"(/data/dicoms_png/)"
data_available_reconverted_mammo_png_images_dn <- r"(/data/dicoms_unconverted_png/)"

# 1. Conversions using original DCMTK version
# Build manifest file for Mirai
mirai_manifest_1 <- data.frame(patient_id = data_available_mammo_png_images_fns$TCode, exam_id = 0, 
                             laterality = data_available_mammo_png_images_fns$ImageLaterality,
                             view = data_available_mammo_png_images_fns$ViewPosition,
                             file_path = paste0(data_available_mammo_png_images_dn, data_available_mammo_png_images_fns$filename))

# 2. Conversions using newer DCMTK version (for remaining unconverted)
# Build manifest file for Mirai
mirai_manifest_2 <- data.frame(patient_id = data_available_reconverted_mammo_png_images_fns$TCode, exam_id = 0, 
                               laterality = data_available_reconverted_mammo_png_images_fns$ImageLaterality,
                               view = data_available_reconverted_mammo_png_images_fns$ViewPosition,
                               file_path = paste0(data_available_reconverted_mammo_png_images_dn, data_available_reconverted_mammo_png_images_fns$filename))

mirai_manifest <- rbind(mirai_manifest_1, mirai_manifest_2)

# Setting these values to constant, as only interested in risk scores for now
mirai_manifest$years_to_cancer <- 0
mirai_manifest$years_to_last_followup <- 0

# All are 'test' set
mirai_manifest$split_group <- 'test'

mirai_manifest <- mirai_manifest %>% arrange(patient_id, view, laterality)

# Export manifest
mirai_manifest_output_dn <- r"(R:\INCANEPI\Generations\Projects\mammo_risk_prediction\data\mirai_manifest.csv)"
write.csv(mirai_manifest, mirai_manifest_output_dn, row.names=F)
