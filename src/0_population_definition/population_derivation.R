## POPULATION GENERATION ##

# This code is intended to define the population used in the mammography risk prediction project
# The population for the project needs to fulfill these criteria:
# - Have appropriate mammography data to generate MIRAI scores
# - Have pedigree information recorded
# - Have cumulus breast density measurements recorded
# - Be approrpiate for a risk validation study, i.e. have follow-up time etc

## Packages
suppressMessages(library(dplyr))
suppressMessages(library(stringr))
suppressMessages(library(lubridate))

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")

## Read in data

# TCodes viable for MIRAI
tcodes_mirai <- read.csv("../../../data/eligible_tcodes.csv") |>
  pull(TCode)

# Pedigree data
data_pedigree <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/Family/Cancer_Pedigree_v1.csv")

# Risk factor data
data_rf <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSRiskFactors.csv")

# Cancer data
data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv")

# Collections data
data_collections <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCollections_v1_Full.csv")

# Cumulus data
data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv") |>
  filter(Reader_ID != "JW")


## Defining population

# Creating dataframe with all TCodes in data_rf
all_tcodes <- data.frame(TCode = data_rf$TCode)

# Creating valid_analytical tag
analytical_set <- create_analytical_dataset(all_tcodes, cancer = "breast", data_rf = data_rf, data_cancer = data_cancer, 
                                            data_fup_start = select(data_collections, TCode, QR0_Age))

# Creating MIRAI tag
all_tcodes$MIRAI <- all_tcodes$TCode %in% tcodes_mirai

# Creating pedigree tag
all_tcodes$pedigree <- all_tcodes$TCode %in% data_pedigree$TCodeParticipant

# Creating cumulus tag
all_tcodes$cumulus <- all_tcodes$TCode %in% data_cumulus$TCode

# Creating analytical_dataset tag
all_tcodes$analytical_dataset <- all_tcodes$TCode %in% analytical_set$TCode

# Filtering down to valid dataset
cat(paste0("Total number of participants: ", nrow(all_tcodes), "\n"))

cat(paste0("Removing ", sum(!all_tcodes$MIRAI), " participants without sufficient mammography data for MIRAI\n"))
all_tcodes <- all_tcodes |> filter(MIRAI)
cat(paste0("Total number of participants: ", nrow(all_tcodes), "\n"))

cat(paste0("Removing ", sum(!all_tcodes$pedigree), " participants without pedigree data\n"))
all_tcodes <- all_tcodes |> filter(pedigree)
cat(paste0("Total number of participants: ", nrow(all_tcodes), "\n"))

cat(paste0("Removing ", sum(!all_tcodes$cumulus), " participants without a cumulus reading\n"))
all_tcodes <- all_tcodes |> filter(cumulus)
cat(paste0("Total number of participants: ", nrow(all_tcodes), "\n"))

cat(paste0("Removing ", sum(!all_tcodes$analytical_dataset), " participants not valid for an analytical dataset\n"))
all_tcodes <- all_tcodes |> filter(analytical_dataset)
cat(paste0("Total number of participants: ", nrow(all_tcodes), "\n"))

## Output final TCode list
write.csv(select(all_tcodes, TCode), "../../../data/analysis_population.csv", row.names = F)


