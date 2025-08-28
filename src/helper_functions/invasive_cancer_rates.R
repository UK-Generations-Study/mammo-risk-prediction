### INASIVE BREAST CANCER RATES GENERATION ###

# This function grabs invasive breast cancer (C50) rates by age group from Cancer registration statistics. England.
# It is designed to get the correct years rates based on the number of years follow-up that is being executed.

# These statistics will change and the function will need to be updated when this happens.

invasive_cancer_rates <- function(icd_code = "C50"){
  
  # Read in the correct years and format data
  cancer_reg_data <- suppressMessages(read.csv("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/data/icare-lit-r-dependencies/Incidence_data_for_England_2024-11-08.csv"))
  
  cancer_reg_data <- cancer_reg_data |>
    filter(ICD10_code == icd_code) |>
    filter(Year == 2015) |> # This year has been determined as around the mean year at start of follow up
    filter(!Age_at_Diagnosis %in% c("Under 1", "All ages")) |> # Removing age groups not needed
    mutate(
      
      # Create specific age based on group - assuming 5 year age bands
      start_age = as.numeric(sub("^(\\d+).*", "\\1", Age_at_Diagnosis)),
      start_age = start_age,
      end_age = as.numeric(sub(".*\\s(\\S+)$", "\\1", Age_at_Diagnosis)),
      end_age = if_else(is.na(end_age), 121, end_age+1), # for iCARE, intervals need to be non-intersecting
      
      # Alter age to be true rate instead of per 100,000
      rate = as.numeric(Rate)/100000,
      
      rate = if_else(is.na(rate), 0, rate)
      
    ) |>
    select(start_age, end_age, rate) |>
    arrange(start_age)
  
  # Pivot to be longer - iCARE has struggled with this format of data
  new_col_invasive_cancer_rates <- data.frame(age = numeric(0), rate = numeric(0))
  for(i in 1:nrow(cancer_reg_data)){
    start <- cancer_reg_data$start_age[i]
    end <- cancer_reg_data$end_age[i]-1
    rate <- cancer_reg_data$rate[i]
    
    df_new <- data.frame(age = start:end, rate = rep(rate, length(start:end)))
    new_col_invasive_cancer_rates <- rbind(new_col_invasive_cancer_rates, df_new)
    
  }
  
  
  # Output data
  return(new_col_invasive_cancer_rates)
  
  
}