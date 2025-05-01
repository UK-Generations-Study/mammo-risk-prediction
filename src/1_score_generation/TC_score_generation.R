### TC SCORE GENERATION ###

# This code is intended to obtain base Tyrer-Cuzick scores for the case-control cohort specified in this analysis
# It does NOT generate new scores, but instead pulls them from a diretory parallel to this repo.
# This is to reduce the chance of error in the score generation process.

## Packages
library(dplyr)

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Read in data

# Population TCodes
tcodes_population <- read.csv("../../../data/analysis_population.csv") |>
  pull(TCode)

# Tyrer-Cuzick scores
tc_dir <- "../../../../Tyrer_Cuzick/TC_Workspace/Base_Cohort_Mort_Adj/"

# Initialise output dataframe
tc_scores <- data.frame()

# Grab list of output files in the location
output_files <- list.files(tc_dir, pattern = "^TC\\_out\\_[0-9]*\\_mort\\.txt")

# Loop through files adding them to output
for(file in output_files){
  
  tc_scores <- rbind(tc_scores, read.csv(paste0(tc_dir, file), header = F)[-1,])
  
}

# Rename output columns
names(tc_scores) <- c("TCode",
                   paste0("Per_", 1:20, "yr"),
                   "Per_Life",
                   "Per_Prob_NoBrca_gene", "Per_Prob_Brca1_gene", "Per_Prob_Brca2_gene",
                   paste0("Pop_", 1:20, "yr"),
                   "Pop_Life",
                   "Pop_Prob_NoBrca_gene", "Pop_Prob_Brca1_gene", "Pop_Prob_Brca2_gene")

# Convert data to numeric
tc_scores[,2:ncol(tc_scores)] <- tc_scores[,2:ncol(tc_scores)] |>
  mutate_all(as.numeric)

# Renaming columns to standard
tc_scores <- tc_scores |>
  rename_with(~ gsub("Per_(\\d+)yr", "absrisk_\\1", .), starts_with("Per_")) |>
  mutate(across(starts_with("absrisk_"), ~ . / 100))


## Filtering scores to case-control population
tc_scores_analysis <- tc_scores |>
  filter(TCode %in% tcodes_population)

## Output data
write.csv(tc_scores_analysis, "../../../data/risk_scores/TC_risk_scores.csv", row.names = F)

