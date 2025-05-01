### CUMULUS SCORE GENERATION ###

# This code is intended to obtain cumulus scores for the case-control subset we are using for this analysis.
# The aim will be to use the cumulus measurement closest to the mammogram selected for MIRAI - this should be the latest mammogram

## Packages
library(dplyr)

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Reading in data

# Population TCodes
tcodes_population <- read.csv("../../../data/analysis_population.csv") |>
  pull(TCode)

# Cumulus measurements
cumulus_measurements <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")

# Mammogram data
data_mammo <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoSet_v1.csv")

## Obtaining Cumulus measurements
cumulus_measurements_analysis <- cumulus_measurements |>
  filter(TCode %in% tcodes_population) |>
  filter(Reader_ID != "JW") |>
  merge(data_mammo |> select(SOPInstanceUID, MammoDate), by = "SOPInstanceUID", all.x = T) |>
  mutate(MammoDate = as.Date(MammoDate, format = "%d/%m/%Y")) |>
  group_by(TCode) |>
  arrange(desc(MammoDate)) |>
  filter(row_number() == 1) |>
  ungroup() |>
  select(TCode, Cumulus_Reading)

## Output data
write.csv(cumulus_measurements_analysis, "../../../data/risk_scores/cumulus_scores.csv", row.names = F)
