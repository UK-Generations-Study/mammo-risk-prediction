library(dplyr)
library(stringr)
library(ggplot2)

data_mammo_images_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoImages_v1.csv)"
data_mammo_images <- read.csv(data_mammo_images_fn, stringsAsFactors = FALSE)

data_mammo_cumulus_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoCumulus_v1.csv)"
data_mammo_cumulus <- read.csv(data_mammo_cumulus_fn, stringsAsFactors = FALSE)

data_mammo_set_fn <- r"(R:\Shared\GENERATIONS\CoreData\v20230927\RDSCCMammoSet_v1.csv)"
data_mammo_set <- read.csv(data_mammo_set_fn, stringsAsFactors = FALSE)


analyze_numstr_column <- function(df, var_name) {
  # Ensure the variable exists in the data frame
  if (!var_name %in% names(df)) {
    stop("Variable not found in data frame.")
  }
  
  # Convert column to numeric, suppressing warnings
  df <- df %>%
    mutate(numeric_var = suppressWarnings(as.numeric(.data[[var_name]])))
  
  # Create the summary table
  count_table <- df %>%
    summarise(
      numeric_count = sum(!is.na(numeric_var) & !is.na(.data[[var_name]])),  # Numeric values
      non_numeric_count = sum(is.na(numeric_var) & !is.na(.data[[var_name]])),  # Non-numeric values
      na_count = sum(is.na(.data[[var_name]]))  # Original NA values
    )
  
  # Extract unique non-numeric values
  unique_non_numeric <- df %>%
    filter(is.na(numeric_var) & !is.na(.data[[var_name]])) %>%
    distinct(.data[[var_name]]) %>%
    pull()
  
  # Return as a list
  return(list(
    count_table = count_table,
    unique_non_numeric_values = unique_non_numeric
  ))
}


analyze_date_column <- function(df, var_name) {
  # Ensure the variable exists in the data frame
  if (!var_name %in% names(df)) {
    stop("Variable not found in data frame.")
  }
  
  # Define the expected date format regex (strict DD/MM/YYYY)
  date_pattern <- "^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$"
  
  # Classify values
  df <- df %>%
    mutate(
      is_valid_date = str_detect(as.character(.data[[var_name]]), date_pattern)
    )
  
  # Create the summary table
  count_table <- df %>%
    summarise(
      valid_date_count = sum(is_valid_date, na.rm = TRUE),   # Matches DD/MM/YYYY
      other_count = sum(!is_valid_date & !is.na(.data[[var_name]])),  # Non-matching values
      na_count = sum(is.na(.data[[var_name]]))  # NA values
    )
  
  # Extract unique non-matching values
  unique_other_values <- df %>%
    filter(!is_valid_date & !is.na(.data[[var_name]])) %>%
    distinct(.data[[var_name]]) %>%
    pull()
  
  # Return as a list
  return(list(
    count_table = count_table,
    unique_other_values = unique_other_values
  ))
}


analyze_date_column(data_mammo_images, "StudyDate_m")
analyze_date_column(data_mammo_images, "SeriesDate_m")
analyze_date_column(data_mammo_images, "AcquisitionDate_m")
analyze_date_column(data_mammo_images, "ContentDate_m")

analyze_numstr_column(data_mammo_images, "SeriesNumber")
analyze_numstr_column(data_mammo_images, "InstanceNumber")
analyze_numstr_column(data_mammo_images, "Rows")
analyze_numstr_column(data_mammo_images, "Columns")
analyze_numstr_column(data_mammo_images, "VariablePixelData")
analyze_numstr_column(data_mammo_images, "PixelRepresentation")
analyze_numstr_column(data_mammo_images, "PixelPaddingValue")

analyze_numstr_column(data_mammo_images, "PhotometricInterpretation")

analyze_numstr_column(data_mammo_images, "PixelIntensityRelationship")
analyze_numstr_column(data_mammo_images, "ImagePixelSpacing")
analyze_numstr_column(data_mammo_images, "Manufacturer")
analyze_numstr_column(data_mammo_images, "ImageType")

analyze_numstr_column(data_mammo_images, "AccessionNumber")
analyze_numstr_column(data_mammo_images, "View_m")
analyze_numstr_column(data_mammo_images, "VariablePixelData")

analyze_numstr_column(data_mammo_images, "Modality")
analyze_numstr_column(data_mammo_images, "BreastImplantPresent")
analyze_numstr_column(data_mammo_images, "PartialView")
analyze_numstr_column(data_mammo_images, "PresentationIntentType")
analyze_numstr_column(data_mammo_images, "StudyDescription")
analyze_numstr_column(data_mammo_images, "LossyImageCompression")
analyze_numstr_column(data_mammo_images, "ProtocolName")
analyze_numstr_column(data_mammo_images, "Exclusion_Missed")
analyze_numstr_column(data_mammo_images, "SOPInstanceUID")


analyze_numstr_column(data_mammo_images, "SeriesDescription") # Dates 
analyze_numstr_column(data_mammo_images, "StudyDescription")  # Location


set_images_joined <- data_mammo_set %>% left_join(data_mammo_images, by = 'SOPInstanceUID')

head(cbind(set_images_joined$View_m, set_images_joined$M_View))
all(set_images_joined$View_m == set_images_joined$M_View)

# Cross-tabulate ImageType.x and View_m
table(set_images_joined$ImageType.x, set_images_joined$View_m, useNA="always")

with(set_images_joined %>% filter(View_m != 'NULL'), table(ImageType.x, Modality, useNA="always"))

# Check for duplicated SOPInstanceUIDs
table(duplicated(set_images_joined$SOPInstanceUID))

# Check how many Cases/Controls per ImageType.x
with(set_images_joined %>% filter(View_m != 'NULL'), table(ImageType.x, CaseControlRequestStatus, useNA="always"))

# Step 1.
table(set_images_joined$ImageType.x)
# a. Investigate ImageType.x: Analogue_C/copied
View(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'))
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), table(Manufacturer))
with(set_images_joined %>% filter(ImageType.x == 'Analogue_copied'), table(Manufacturer))
set_images_joined[set_images_joined[,'ImageType.x'] == 'Analogue_copied','ImageType.x'] <- 'Analogue_Copied'
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "PixelRepresentation")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "PixelIntensityRelationship")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "PresentationIntentType")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "ProtocolName")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "PartialView")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "PhotometricInterpretation")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "ImageType.y")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), "Modality")
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied'), table(Modality))
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Copied', Modality == 'MG'), table(Manufacturer))
# b. Investigate ImageType.x: Analogue_Digitised
View(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'))
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), table(Manufacturer))
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "PixelRepresentation")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "PixelIntensityRelationship")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "Pixel_Int")
#View(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised') %>% select('PixelIntensityRelationship', 'Pixel_Int'))
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "PresentationIntentType")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "ProtocolName")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "PartialView")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "PhotometricInterpretation")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "ImageType.y")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), "Modality")
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised'), table(Modality))
with(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised', Modality == 'MG'), table(Manufacturer))
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised',  Modality == 'MG'), "Pixel_Int")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised',  Modality == 'MG'), "ProtocolName")

View(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised', Modality == 'MG', Manufacturer=='HOLOGIC, Inc.'))
View(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised', Modality == 'MG'))
# c. Investigate ImageType.x: Digital_Processed
with(set_images_joined %>% filter(ImageType.x == 'Digital_Processed', Modality == 'MG'), table(Manufacturer))
View(set_images_joined %>% filter(ImageType.x == 'Digital_Processed', Modality == 'MG', Manufacturer=='HOLOGIC, Inc.'))
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Digital_Processed',  Modality == 'MG'), "Pixel_Int")
analyze_numstr_column(set_images_joined %>% filter(ImageType.x == 'Digital_Processed',  Modality == 'MG'), "ProtocolName")


# 2. Identify HOLOGIC DICOMs
with(set_images_joined %>% filter(Modality == 'MG'), table(Manufacturer))
with(set_images_joined %>% filter(Modality == 'MG',
                                                   Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')), table(ImageType.x))
with(set_images_joined %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')), table(ImageType.x)) # Same
View(set_images_joined %>% filter(ImageType.x == 'Analogue_Digitised', Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')))
View(set_images_joined %>% filter(ImageType.x == 'Digital_Processed', Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')))

ggplot(set_images_joined, aes(x = YearOfMammo, fill = ImageType.x, color = ImageType.x)) +
  geom_density(alpha = 0.4, linewidth=1) + 
  labs(title = "Density of YearOfMammo by ImageType",
       x = "Year of Mammogram",
       y = "Density",
       fill = "Image Type",
       color = "Image Type") +
  theme_minimal() + theme(panel.border = element_rect(fill=NA,color='black'))

ggplot(set_images_joined %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')),
       aes(x = YearOfMammo, fill = ImageType.x, color = ImageType.x)) +
  geom_density(alpha = 0.4, linewidth=1) + 
  labs(title = "Density of YearOfMammo by ImageType (HOLOGIC/LORAD)",
       x = "Year of Mammogram",
       y = "Density",
       fill = "Image Type",
       color = "Image Type") +
  theme_minimal() + theme(panel.border = element_rect(fill=NA,color='black'))


# Check Manufacturer
with(set_images_joined %>% filter(View_m != 'NULL', ImageType.x == 'Digital_Processed'), table(Manufacturer, ImageType.x, useNA="always"))

# Check PresentationIntentType
with(set_images_joined %>% filter(View_m != 'NULL', ImageType.x == 'Digital_Processed'), table(PresentationIntentType, ImageType.x, useNA="always"))



# How many Hologics do we have?
set_images_joined %>% filter(Manufacturer %in% c('HOLOGIC, Inc.', 'LORAD', 'Lorad, A Hologic Company')) %>% group_by(ImageType.x, ManuModelName) %>% summarise(participants=length(unique(TCode.x)))