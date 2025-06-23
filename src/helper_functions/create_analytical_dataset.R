###  ANALYTICAL DATASET GENERATION ###

# This function is designed to take the output of a risk generation program and format it into a dataset suitable for analysis.
# This means removing prior cancers (breast cancers only at this point) and adding in risk factors, as well as removing participants for other reasons.

# Inputs:
#   output - dataset containing results of risk generation by TCode. Absolute risks for a year x should have the column name absrisk_x and linear predictor should be lp
#   years - the number of years the analysis will take place over. Will remove any participant with less than that many years follow up (unless they died). NA is a valid option that incdicates the validation will be done over the follow up time.
#   min_age - minimum age for cohort
#   max_age - maximum age for cohort
#   cancer - the cancer we are measuring as an event. Either "breast" or "colorectal" currently
#   fup_start_date - if not using fupca_start_F, an alternative date to use as the start of follow up

# Function
create_analytical_dataset <- function(output, years = NA, min_age = NA, max_age = NA, cancer = "breast", data_rf = NULL, data_cancer = NULL, data_fup_start = NULL, data_exclusions = NULL, fup_start_date = NULL){
  
  # Load in dependent functions
  #source(r"(C:\Users\rfrost\OneDrive - The Institute of Cancer Research\Documents\Analysis\Functions\Load_RDS_data.R)")
  source("../helper_functions/Load_RDS_data.R")
  
  # Read in risk factor/cancer data
  if(is.null(data_rf)){
    data_rf <- load_RDS_data("v20230927", "RDSRiskFactors.csv")
  }
  
  if(is.null(data_cancer)){
    data_cancer <- load_RDS_data("v20230927", "RDSCaSummary_V1.csv")
  }
  
  if(is.null(data_fup_start)){
    data_fup_start <- load_RDS_data("v20230927", "RDSCollections_v1_Full.csv") |>
      select(TCode, QR0_Age)
  }
  
  if(is.null(data_exclusions)){
    data_exclusions <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/RDSExclusions.csv")
    # 
  }
  
  # If fup_start_date variable chosen - check it has been selected in output
  if(!is.null(fup_start_date)){
    if(!fup_start_date %in% names(output)){
      stop(paste0("ERROR: ", fup_start_date, " not found in output"))
    }
  }
  
  # Need to grab age at event (invasive cancer) and whether it was a breast cancer or not
  data_cancer <- data_cancer %>%
    mutate(
      # Create new variables and recode position 0 to 999
      # so 'no registry' or 'no reported' info is last
      reginfo_clusterino99 = ifelse(Reginfo_Clusterino == 0, 999, Reginfo_Clusterino),
      report_cluster99 = ifelse(Report_Cluster == 0, 999, Report_Cluster),
      
      date_diag = as.Date(diagdate_f, format = "%Y-%m-%d %H:%M:%S"),
      
      # Invasive or DCIS-breast cancer or  LCIS-breast cancer
      # NOTE: is this the right response variable?
      breast_cancer = if_else(
        (str_sub(ICDt, 1, 3) == "C50") |
          (str_sub(ICDt, 1, 3) == "174") |
          (str_sub(ICDt, 1, 4) == "D050") |
          (str_sub(ICDt, 1, 4) == "D051") |
          (str_sub(ICDt, 1, 4) == "D059") |
          (str_sub(ICDt, 1, 4) == "2330"), 1, 0),
      
      # Invasive colorectal cancer
      colorectal_cancer = if_else(
        (str_sub(ICDt, 1, 3) == "C18") |
          (str_sub(ICDt, 1, 3) == "C19") |
          (str_sub(ICDt, 1, 3) == "C20") |
          (str_sub(ICDt, 1, 3) == "153") |
          (str_sub(ICDt, 1, 3) == "154"), 1, 0)
      
    )
  
  # Select first (per woman)
  # ! This is an analysis specific decision
  # ! different analyses may want different selection criteria
  # Only care about breast cancers in this case
  data_cancer <- data_cancer %>%
    filter(!!sym(paste0(cancer, "_cancer")) == 1) |>
    arrange(TCode, date_diag, reginfo_clusterino99, report_cluster99) %>%
    group_by(TCode) %>%
    mutate(n_tcode = order(TCode)) %>%
    filter(n_tcode == 1) %>%
    ungroup() |>
    select(TCode, date_diag, !!sym(paste0(cancer, "_cancer")), diagyear)
  
  
  # merge fup start into dataset if needed
  if(!is.null(fup_start_date)){
    study.data <- data_rf |>
      merge(select(output, TCode, !!sym(fup_start_date)), all.y = T) |>
      select(-fupca_start_F) |>
      rename(fupca_start_F = !!sym(fup_start_date))
  } else {
    study.data <- data_rf
  }
  
  # merge cancers into main dataset
  study.data <- study.data |>
    merge(data_cancer, by.x = "TCode", by.y = "TCode", all.x = T) |>
    merge(data_fup_start, by = "TCode", all.x = T) |>
    crosstable::remove_labels() |>
    mutate(
      
      time.of.onset = case_when(
        is.na(date_diag) ~ Inf,
        TRUE ~ time_length(interval(fupca_start_F, date_diag), unit = "years")),
      
      observed.outcome = ifelse(is.na(!!sym(paste0(cancer, "_cancer"))), 0, !!sym(paste0(cancer, "_cancer"))),
      
      study.entry.age = time_length(interval(start = ADOB_F, end = fupca_start_F), unit = "years"),
      
      age.at.onset = case_when(
        is.na(date_diag) ~ NA,
        TRUE ~ time_length(interval(ADOB_F, date_diag), unit = "years")),
      
      study.exit.age = time_length(interval(start = ADOB_F, end = fupca_end_F), unit = "years"),
      
      
    )
  
  # Merge output into study.data
  study.data <- study.data |>
    merge(output, by = "TCode", all.y = T)
  
  
  
  ## Removing participants who don't meet analytical needs
  
  cat(paste0("\n\nNumber of participants: ", nrow(study.data)))
  
  # Removing participants with invalid entry/exit ages
  study.data_2 <- study.data |>
    filter(study.exit.age > study.entry.age | is.na(QR0_Age))
  
  cat(paste0("\n\nRemoving ", nrow(study.data) - nrow(study.data_2), " participants with invalid start/end ages\n\nNumber of participants: ", nrow(study.data_2)))
  
  # Removing participants with prior breast cancer (invasive/DCIS)
  study.data_3 <- study.data_2 |>
    filter(time.of.onset >= 0)
  
  cat(paste0("\n\nRemoving ", nrow(study.data_2) - nrow(study.data_3), " participants with prior ",  cancer , " cancer\n\nNumber of participants: ", nrow(study.data_3)))
  
 # Removing participants outside age bounds
  if(!is.na(min_age) & !is.na(max_age)){
    
    study.data_4 <- study.data_3 |>
      filter(study.entry.age >= min_age & floor(study.entry.age) <= max_age)
    
    cat(paste0("\n\nRemoving ", nrow(study.data_3) - nrow(study.data_4), " outside age boundary: [",min_age, ", ", max_age, "]\n\nNumber of participants: ", nrow(study.data_4)))
    
  } else if(!is.na(min_age)){
    
    study.data_4 <- study.data_3 |>
      filter(study.entry.age >= min_age)
    
    cat(paste0("\n\nRemoving ", nrow(study.data_3) - nrow(study.data_4), " outside age boundary: [",min_age, ", Inf)\n\nNumber of participants: ", nrow(study.data_4)))
    
  } else if(!is.na(max_age)){
    
    study.data_4 <- study.data_3 |>
      filter(floor(study.entry.age) <= max_age)
    
    cat(paste0("\n\nRemoving ", nrow(study.data_3) - nrow(study.data_4), " outside age boundary: [0, ", max_age, "]\n\nNumber of participants: ", nrow(study.data_4)))
    
  } else {
    
    study.data_4 <- study.data_3
    
  }
  
  # Removing participants with not enough follow up time - unless their reason is that they have died
  if(!is.na(years)){
    
    study.data_5 <- study.data_4 |>
      filter(study.exit.age - study.entry.age >= years | fupca_end_reason == 22)
    
    cat(paste0("\n\nRemoving ", nrow(study.data_4) - nrow(study.data_5), " participants with insufficient follow up time\n\nNumber of participants: ", nrow(study.data_5)))
    
  } else {
    
    study.data_5 <- study.data_4
    
  }
  
  
  # Removing participants with invalid risk score
  study.data_6 <- study.data_5 |>
    filter(if_all(starts_with("absrisk_"), ~ !is.na(.)))
  
  if("lp" %in% colnames(study.data_6)){
    study.data_6 <- filter(study.data_6, !is.na(lp))
  }
  
  cat(paste0("\n\nRemoving ", nrow(study.data_5) - nrow(study.data_6), " with invalid risk scores\n\nNumber of participants: ", nrow(study.data_6)))
  
  # Removing participants to be excluded
  study.data_7 <- study.data_6 |>
    filter(!(TCode %in% data_exclusions$TCode))
  
  cat(paste0("\n\nRemoving ", nrow(study.data_6) - nrow(study.data_7), " to be excluded\n\nNumber of participants: ", nrow(study.data_7)))
  
  
  # Output dataset
  return(study.data_7)
  
}

get_earliest_cancer <- function(data_cancer = NULL, cancer = "breast"){
  
  # Read in data
  if(is.null(data_cancer)){
    
    # Load in data_cancer
    data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv")
    
  }
  
  # Need to grab age at event (invasive cancer) and whether it was a breast cancer or not
  data_cancer <- data_cancer %>%
    filter(!is.null(TCode)) |>
    mutate(
      # Create new variables and recode position 0 to 999
      # so 'no registry' or 'no reported' info is last
      reginfo_clusterino99 = ifelse(Reginfo_Clusterino == 0, 999, Reginfo_Clusterino),
      report_cluster99 = ifelse(Report_Cluster == 0, 999, Report_Cluster),
      
      date_diag = as.Date(diagdate_f, format = "%Y-%m-%d %H:%M:%S"),
      
      # Invasive or DCIS-breast cancer or  LCIS-breast cancer
      # NOTE: is this the right response variable?
      breast_cancer = if_else(
        (str_sub(ICDt, 1, 3) == "C50") |
          (str_sub(ICDt, 1, 3) == "174") |
          (str_sub(ICDt, 1, 4) == "D050") |
          (str_sub(ICDt, 1, 4) == "D051") |
          (str_sub(ICDt, 1, 4) == "D059") |
          (str_sub(ICDt, 1, 4) == "2330"), 1, 0),
      
      # Invasive colorectal cancer
      colorectal_cancer = if_else(
        (str_sub(ICDt, 1, 3) == "C18") |
          (str_sub(ICDt, 1, 3) == "C19") |
          (str_sub(ICDt, 1, 3) == "C20") |
          (str_sub(ICDt, 1, 3) == "153") |
          (str_sub(ICDt, 1, 3) == "154"), 1, 0)
      
    )
  
  # Select first (per woman)
  # ! This is an analysis specific decision
  # ! different analyses may want different selection criteria
  # Only care about breast cancers in this case
  data_cancer <- data_cancer %>%
    filter(!!sym(paste0(cancer, "_cancer")) == 1) |>
    arrange(TCode, date_diag, reginfo_clusterino99, report_cluster99) %>%
    group_by(TCode) %>%
    mutate(n_tcode = order(TCode)) %>%
    filter(n_tcode == 1) %>%
    ungroup() |>
    select(TCode, date_diag, !!sym(paste0(cancer, "_cancer")), diagyear)
  
  return(data_cancer)
  
  
}
