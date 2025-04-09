### COMPETING MORTALITY RATES GENERATION ###

# This function grabs competing mortality rates by age for women using ONS data on mortality and population.
# It is designed to get the correct years rates based on the number of years follow-up that is being executed.


competing_mort_rates <- function(icd_code = "C50"){
  
  # Read in mortality data
  data_mort <- read_excel(r"(C:\Users\rfrost\OneDrive - The Institute of Cancer Research\Documents\Analysis\Data\dr2022corrected.xlsx)", sheet = "6")
  
  # Clean mortality data
  colnames(data_mort) <- data_mort[4,]
  data_mort <- data_mort[-(1:4),]
  
  # Extract necessary data
  data_mort <- data_mort |>
    filter(`Year of registration` == 2006) |>
    select(-`All ages`, -`Year of registration`) |>
    pivot_longer(cols = everything(), names_to = "age_string", values_to = "count") |>
    mutate(
      
      age = as.numeric(gsub("Aged\\s|\\syears|\\syears\\sand\\sabove", "", age_string))
      
    ) |>
    select(age, count) |>
    mutate(
      
      age_group = cut(age, breaks = seq(0,110, by = 5), right = F)
      
    ) |>
    group_by(age_group) |>
    reframe(
      
      start_age = as.numeric(gsub("\\[|\\(|,.*", "", age_group)),
      
      end_age = as.numeric(gsub(".*,|\\)|\\(", "", age_group)),

      mort_count = sum(as.numeric(count))
      
    ) |>
    distinct()
  
  
  # Read in cancer mortality data
  data_cancer_mort <- read.csv(r"(C:\Users\rfrost\OneDrive - The Institute of Cancer Research\Documents\Analysis\Data\Mortality_data_for_England_2024-11-12.csv)")
  
  data_cancer_mort <- data_cancer_mort  |>
    filter(Year == 2006) |>
    filter(ICD10_code == icd_code) |>
    filter(!Age_at_Diagnosis %in% c("Under 1", "All ages")) |>
    mutate(
      
      # Create specific age based on group - assuming 5 year age bands
      start_age = as.numeric(sub("^(\\d+).*", "\\1", Age_at_Diagnosis)),
      start_age = if_else(start_age == 1, 0, start_age),
      end_age = as.numeric(sub(".*\\s(\\S+)$", "\\1", Age_at_Diagnosis))+1,
      end_age = if_else(is.na(end_age), 120, end_age),
      
      age_group = paste0("[", start_age, ",", end_age, ")")
      
    ) |>
    select(age_group, start_age, end_age, cancer_mort_count = Count)
  
  
  # Need to combine to find non-cancer site mortality count per age
  # Need to combine top ages in overall mortality
  data_mort <- data_mort |>
    mutate(
      
      age_group_new = if_else(start_age>=90, "A", as.character(row_number()))
      
    ) |>
    group_by(age_group_new) |> 
    summarise(age_group = paste0("[", min(start_age), ",", max(end_age), ")"), start_age = min(start_age), end_age = max(end_age), mort_count = sum(mort_count)) |>
    select(-age_group_new)

  # Now combine and find total non-cancer site deaths
  data_mort_all <- merge(data_mort, data_cancer_mort, by = c("age_group", "start_age", "end_age")) |>
    mutate(
      
      non_c50_mort_count = mort_count - cancer_mort_count
      
    )
  
  # Read in population data
  data_pop <- read_excel(r"(C:\Users\rfrost\OneDrive - The Institute of Cancer Research\Documents\Analysis\Data\regionalpopestimatesenglandandwales19712023.xlsx)", sheet = "Table 4", na = "missing data")
  
  colnames(data_pop) <- data_pop[1,]
  data_pop <- data_pop[-1,]
  
  # NOTE: Need to account for earlier years having NA data for older ages potentially
  
  data_pop <- data_pop |>
    filter(Year == 2006) |>
    select(all_of(starts_with("F"))) |>
    mutate(across(everything(), as.numeric)) |>
    summarise(across(everything(), sum)) |>
    pivot_longer(everything(), names_to = "age_string", values_to = "pop_count") |>
    mutate(
      
      age = gsub("F", "", age_string),
      age = as.numeric(if_else(grepl("\\/|\\+", age), str_sub(age, 1, 2), age)),
      
      age_group = cut(age, breaks = seq(0, 95, by = 5), right = F),
      
      start_age = as.numeric(gsub("\\[|\\(|,.*", "", age_group)),
      
      end_age = as.numeric(gsub(".*,|\\)|\\(", "", age_group)),
      
      
    ) |>
    select(age_group, start_age, end_age, pop_count) |>
    mutate(
      
      age_group = if_else(start_age>=85, "[85,120)", age_group)
      
    ) |>
    group_by(age_group) |>
    summarise(pop_count = sum(pop_count)) |>
    mutate(
      
      start_age = as.numeric(gsub("\\[|\\(|,.*", "", age_group)),
      
      end_age = as.numeric(gsub(".*,|\\)|\\(", "", age_group))
      
    )
    

  # Now we need to group the top 2 for mortality
  data_mort_all <- data_mort_all |>
    mutate(
      
      age_group = if_else(start_age >= 85, "[85,120)", age_group)
      
    ) |>
    group_by(age_group) |>
    summarise(non_c50_mort_count = sum(non_c50_mort_count))

  # Now we can combine mortality data and population data to get rates
  data_final <- merge(data_mort_all, data_pop, by = "age_group") |>
    mutate(
      
      start_age = as.numeric(gsub("\\[|\\(|,.*", "", age_group)),
      
      end_age = as.numeric(gsub(".*,|\\)|\\(", "", age_group)),
      
      mort_rate = non_c50_mort_count/pop_count
      
    ) |>
    select(start_age, end_age, mort_rate) |>
    arrange(start_age)
  
  # NOTE: If needing ages above 87.5, simply extend out mortality rate - it is a 'greater than 85' category in truth
  
  # Pivot to be longer - iCARE has struggled with this format of data
  new_data_final <- data.frame(age = numeric(0), mort_rate = numeric(0))
  for(i in 1:nrow(data_final)){
    start <- data_final$start_age[i]
    end <- data_final$end_age[i]-1
    mort_rate <- data_final$mort_rate[i]
    
    df_new <- data.frame(age = start:end, mort_rate = rep(mort_rate, length(start:end)))
    new_data_final <- rbind(new_data_final, df_new)
    
  }
  
  
  # Output data
  return(new_data_final)
  
  
}
