### CUMULUS SUB COHORT INVESTIGATION ###

## Packages
library(dplyr)
library(ggplot2)

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Read in data

data_cohort <- read.csv("../../../data/analysis_population.csv")

data_rf <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSRiskFactors.csv", na.strings = c("NA","","NULL"))

data_cancer <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCaSummary_V1.csv", na.strings = c("NA","","NULL")) |>
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
    
  ) |>
  filter(breast_cancer == 1) |>
  arrange(TCode, date_diag, reginfo_clusterino99, report_cluster99) %>%
  group_by(TCode) %>%
  mutate(n_tcode = order(TCode)) %>%
  filter(n_tcode == 1) %>%
  ungroup() |>
  select(TCode, date_diag, breast_cancer, diagyear)

data_rf <- data_rf |>
  merge(data_cancer, by = "TCode", all.x = T) |>
  mutate(
    
    time.of.onset = case_when(
      is.na(date_diag) ~ Inf,
      TRUE ~ time_length(interval(fupca_start_F, date_diag), unit = "years")
    ),
    
    case_5yr = if_else(!is.na(time.of.onset) & time.of.onset <= 5, 1, 0)
    
  )
  
data_cumulus <- read.csv("../../../data/risk_scores/cumulus_scores.csv")

## Functions
my_xtabs <- function(data, variable){
  
  if(!"sampling.weight" %in% names(data)){
    data$sampling.weight <- 1
  }
  
  tab <- xtabs(as.formula(paste0("sampling.weight ~ cumulus_cohort + ", variable)), data = data)
  tab <- tab/rowSums(tab)
  
  return(tab)

}

## Look at variables to see differences 

data_rf_study <- data_rf |>
  mutate(
    
    total_cohort = TCode %in% data_cohort$TCode,
    cumulus_cohort = TCode %in% data_cumulus$TCode
    
  ) |>
  filter(total_cohort)

data_rf_study <- data_rf_study |>
  rbind(data_rf_study |> filter(cumulus_cohort) |> mutate(cumulus_cohort = F)) |>
  mutate(sampling.weights = 1)

# Age
ggplot(data_rf_study, aes(x = as.numeric(AgeatEntry), fill = cumulus_cohort)) +
  geom_density(alpha = 0.4, aes(weights = sampling.weights))

### WEIGHTING BASED ON AGE ###

data_rf_study <- data_rf_study |>
  mutate(age.cat = cut(AgeatEntry, breaks = seq(20, 100, by = 5)))

total_table <- 




### END OF WEIGHTING BASED ON AGE ###


#  Family History of BC
my_xtabs(data_rf_study, "fambrca")

# 5 year case/control status
my_xtabs(data_rf_study, "case_5yr")


# BMI
ggplot(data_rf_study |> filter(bodysizebminow < 600), aes(x = as.numeric(bodysizebminow), fill = cumulus_cohort)) +
  geom_density(alpha = 0.4, aes(weights = sampling.weights))

# Parity
my_xtabs(data_rf_study |> filter(between(as.numeric(pregparitycnt), -1, 15)) |> mutate(parous = pregparitycnt > 0), "parous")

# OC status
my_xtabs(data_rf_study|> filter(ocstatus != 999), "ocstatus")

# Menopausal status
my_xtabs(data = data_rf_study |> mutate(meno_status = case_when(
  R1menopause %in% c(1,3) ~ 1, # Postmenopausal
  R1menopause %in% c(2,4) ~ 2, # Premenopausal
  R1menopause %in% c(8,9,10) ~ NA, # Should "never had periods" be in not known section or Perimenopausal/other section?
  TRUE ~ NA)), "meno_status")

