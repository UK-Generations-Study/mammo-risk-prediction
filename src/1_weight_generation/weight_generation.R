### WEIGHT DERIVATION ###

# In order to conduct analysis on the case-control cohort in this study, we need to find appropriate weightings.
# This will be done by first subsetting the generations cohort to a subset that are 'valid' for selection into the case-control cohort,
# and then attempting to calculate weights on this population, based on tyrer-cuzick scores.

# NOTE: Initially scores will be taken from the tyrer-cuzick repo, but this will be updated to be more standalone in future.

## Packages
suppressMessages(library(dplyr))
suppressMessages(library(stringr))
suppressMessages(library(lubridate))
suppressMessages(library(readr))
suppressMessages(library(sqldf))
suppressMessages(library(Hmisc))

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../helper_functions/invasive_cancer_rates.R")
source("../helper_functions/iCARE_validate_and_plot.R")

## Read in TC scores
# Initialise output dataframe
output <- data.frame()

# Grab list of output files in the location
filepath <- "../../../../Tyrer_Cuzick/TC_Workspace/Base_Cohort_Mort_Adj/"
output_files <- list.files(filepath, pattern = "^TC\\_out\\_[0-9]*\\_mort\\.txt")

# Loop through files adding them to output
for(file in output_files){
  
  output <- rbind(output, read.csv(paste0(filepath, file), header = F)[-1,])
  
}

# Rename output columns
names(output) <- c("TCode",
                   paste0("Per_", 1:20, "yr"),
                   "Per_Life",
                   "Per_Prob_NoBrca_gene", "Per_Prob_Brca1_gene", "Per_Prob_Brca2_gene",
                   paste0("Pop_", 1:20, "yr"),
                   "Pop_Life",
                   "Pop_Prob_NoBrca_gene", "Pop_Prob_Brca1_gene", "Pop_Prob_Brca2_gene")

# Convert data to numeric
output[,2:ncol(output)] <- output[,2:ncol(output)] |>
  mutate_all(as.numeric)

# Renaming columns to standard
output <- output |>
  rename_with(~ gsub("Per_(\\d+)yr", "absrisk_\\1", .), starts_with("Per_")) |>
  mutate(across(starts_with("absrisk_"), ~ . / 100))


## Read in data

# Risk factor data
data_rf <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSRiskFactors.csv")
data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv")

# Analytical population
population_tcodes <- read.csv("../../../data/analysis_population.csv") |>
  pull(TCode)

# Invasive cancer rates
incidence_rates <- invasive_cancer_rates(icd_code = "C50")

## Create analytical dataset from TC scores
base_analytical_dataset <- create_analytical_dataset(output, years = NA, min_age = 25, max_age = 75, data_rf = data_rf, data_cancer = data_cancer)

# If censoring age is used, create censoring age
base_analytical_dataset <- create_cen_risk(base_analytical_dataset)


# Calculate Relative Risk
base_analytical_dataset$lp <- unlist(sapply(floor(base_analytical_dataset$study.entry.age), function(x){
  return(incidence_rates$rate[incidence_rates$age == x])
}))

base_analytical_dataset$lp <- base_analytical_dataset$absrisk_1/unlist(base_analytical_dataset$lp)

## Run model validation on this cohort
base_analytical_validation <- iCARE_validate_and_plot(base_analytical_dataset,
                                                  years = NA,
                                                  filepath = "../../plots/1_weight_generation/base_cohort.png",
                                                  dataset_name = "Whole Cohort",
                                                  model_name = "Tyrer Cuzick",
                                                  decile.variable = "linear.predictor",
                                                  output = T)


## Find sub-cohort that is valid for the case-control cohort

# Define inclusion variable
data_rf <- data_rf |>
  mutate(cohort_included = TCode %in% population_tcodes)

# Stratifying on suspected exclusion criteria

# Caucasian
table(data_rf$ethnew5, data_rf$cohort_included, useNA = "always") # There seems to be a few exceptions

# Menopausal status
table(data_rf$R1menopause, data_rf$cohort_included, useNA = "always") # There seems to be a few exceptions

# Investigate menopause ages of those listed as premenopausal
data_rf |>
  filter(cohort_included & R1menopause == "2.0") |>
  mutate(
    
    time_to_menopause = case_when(
      meno_age == "888.0" ~ NA,
      meno_age == "777.0" ~ NA,
      meno_age == "999.0" ~ NA,
      TRUE ~ as.numeric(meno_age) - as.numeric(AgeatEntry)
    )
    
  ) |>
  pull(time_to_menopause) |>
  summary()

# HRT Usage
table(data_rf$hrtstatus, data_rf$cohort_included, useNA = "always") # There seems to be a few exceptions

## Attempt to make weights based on simple tabulation

# age x diagyear
data_cancer_tab <- data_cancer |>
  mutate(
    # Invasive or DCIS-breast cancer
    # NOTE: is this the right response variable?
    breast_cancer = if_else(
      (str_sub(ICDt, 1, 3) == "C50") |
        (str_sub(ICDt, 1, 3) == "174") |
        (str_sub(ICDt, 1, 4) == "D051") |
        (str_sub(ICDt, 1, 4) == "D059") |
        (str_sub(ICDt, 1, 4) == "2330"), 1, 0)
  ) |>
  filter(breast_cancer == 1) |>
  group_by(TCode) |>
  summarise(diagyear = min(diagyear))

data_rf_tab <- data_rf |>
  filter(!is.na(AgeatEntry)) |>
  merge(data_cancer, by = "TCode", all.x = T) |>
  mutate(
    
    age = cut(as.numeric(AgeatEntry), breaks = seq(20, 120, by = 10)),
    diagyear = if_else(is.na(diagyear), "Control", cut(diagyear, breaks = seq(1940, 2030, by = 10)))
    
  )
