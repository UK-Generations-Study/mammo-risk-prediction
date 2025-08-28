### UPDATED iCARE-Lit SCORE GENERATION ###

# This function is intended to take as input a list of TCodes with an associated list of age that consist of the start of the follow up time
# The input should be structured as the output from create_analytical_dataset()
# It will then output the iCARE-Lit 5 year absolute risk scores

# Inputs:
#   df - dataset containing TCodes with the column name "TCode" and age of follow up start with the column name "study.entry.age"

iCARE_Lit_score_generation <- function(df){
  
  # Read in risk factor data
  data_rf <- load_RDS_data("v20230927", "RDSRiskFactors.csv") |>
    crosstable::remove_labels()
  
  # Clean df to generate iCARE-Lit scores
  df <- df |>
    select(TCode, study.entry.age) |>
    merge(data_rf, by = "TCode", all.x = T) |>
    mutate(
      
      # TCode
      TCode = TCode,
      
      # Age
      age = study.entry.age,
      
      # Age at menarche
      age_at_menarche = case_when(
        menarcheage %in% c(888, 999) ~ NA,
        menarcheage == 777 ~ NA,
        menarcheage > age ~ NA,
        TRUE ~ menarcheage
      ),
      
      # Age at first birth
      age_first_birth = time_length(interval(start = ADOB_F, end = pregdate_1_f), unit = "year"),
      
      age_first_birth = case_when(
        is.na(age_first_birth) ~ NA,
        age_first_birth > age ~ NA,
        TRUE ~ age_first_birth
      ),
      
      # Parity
      age_second_birth = time_length(interval(start = ADOB_F, end = pregdate_2_f), unit = "year"),
      age_third_birth = time_length(interval(start = ADOB_F, end = pregdate_3_f), unit = "year"),
      
      parity = case_when(
        is.na(age_first_birth) ~ "0",
        is.na(age_second_birth) | age_second_birth > age ~ "1",
        is.na(age_third_birth) | age_third_birth > age ~ "2",
        TRUE ~ ">=3"
      ),
      
      # OC current
      oc_current = case_when(
        if_all(c(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4), is.na) ~ 0,
        !is.na(OCHTstartage_1) & !is.na(OCHTendage_1) & between(age, OCHTstartage_1, OCHTendage_1) ~ 1, 
        !is.na(OCHTstartage_2) & !is.na(OCHTendage_2) & between(age, OCHTstartage_2, OCHTendage_2) ~ 1, 
        !is.na(OCHTstartage_3) & !is.na(OCHTendage_3) & between(age, OCHTstartage_3, OCHTendage_3) ~ 1, 
        !is.na(OCHTstartage_4) & !is.na(OCHTendage_4) & between(age, OCHTstartage_4, OCHTendage_4) ~ 1, 
        TRUE ~ 0
      ),
      
      # OC ever
      oc_ever = case_when(
        if_all(c(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4), is.na) ~ 0,
        pmin(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4, na.rm = T) < age ~ 1,
        TRUE ~ 0
      ),
      
      # Alcohol intake
      alcohol_intake = case_when(
        is.na(alcoholstartage) | is.na(alcoholstopage) ~ NA,
        alcoholstartage > age | alcoholstopage < age ~ 0,
        age > R4Age & R4Age >= alcoholstartage & !is.na(R4alcoholunits) ~ R4alcoholunits,
        age > R2Age & R2Age >= alcoholstartage & !is.na(R4alcoholunits) ~ R2alcoholunits,
        TRUE ~ R1alcoholunits
      ),
      
      alcohol_intake = 8*alcohol_intake/7,
      
      # Benign breast disease
      # Need to see if this is updateable
      bbd = case_when(
        is.na(brbendis) ~ NA,
        brbendis == 2 ~ 0,
        TRUE ~ brbendis
      ),
      
      # Family history of breast cancer
      # Need to see if this is updateable
      famhist = fambrca,
      
      # Age at menopause
      age_at_menopause = case_when(
        meno_age == 999 ~ NA,
        meno_age == 777 ~ NA,
        meno_age > age ~ NA,
        TRUE ~ meno_age
      ),
      
      # Height
      # Believe this variable is not updated
      height = case_when(
        bodysizeht == 989 ~ NA,
        TRUE ~ bodysizeht
      ),
      
      # HRT
      hrt = case_when(
        if_all(c(HRTstartage_1, HRTstartage_2, HRTstartage_3, HRTstartage_4,HRTendage_1,HRTendage_2,HRTendage_3,HRTendage_4), is.na) ~ "Never",
        !is.na(HRTstartage_1) & !is.na(HRTendage_1) & between(age, HRTstartage_1, HRTendage_1) ~ "Current", 
        !is.na(HRTstartage_2) & !is.na(HRTendage_2) & between(age, HRTstartage_2, HRTendage_2) ~ "Current", 
        !is.na(HRTstartage_3) & !is.na(HRTendage_3) & between(age, HRTstartage_3, HRTendage_3) ~ "Current", 
        !is.na(HRTstartage_4) & !is.na(HRTendage_4) & between(age, HRTstartage_4, HRTendage_4) ~ "Current", 
        !is.na(HRTendage_1) & HRTendage_1 < age & (if_all(c(HRTstartage_2, HRTstartage_3, HRTstartage_4,HRTendage_2,HRTendage_3,HRTendage_4), is.na) | pmin(HRTstartage_2, HRTstartage_3, HRTstartage_4,HRTendage_2,HRTendage_3,HRTendage_4, na.rm = T) > age) ~ "Former",
        !is.na(HRTendage_2) & HRTendage_2 < age & (if_all(c(HRTstartage_3, HRTstartage_4,HRTendage_3,HRTendage_4), is.na) | pmin(HRTstartage_3, HRTstartage_4,HRTendage_3,HRTendage_4, na.rm = T) > age) ~ "Former",
        !is.na(HRTendage_3) & HRTendage_3 < age & (if_all(c(HRTstartage_4,HRTendage_4), is.na) | pmin(HRTstartage_4, HRTendage_4, na.rm = T) > age) ~ "Former",
        !is.na(HRTendage_4) & HRTendage_4 < age ~ "Former",
        TRUE ~ NA
      ),
      
      hrt_current_period = case_when(
        if_all(c(HRTstartage_1, HRTstartage_2, HRTstartage_3, HRTstartage_4,HRTendage_1,HRTendage_2,HRTendage_3,HRTendage_4), is.na) ~ NA,
        !is.na(HRTstartage_1) & !is.na(HRTendage_1) & between(age, HRTstartage_1, HRTendage_1) ~ 1, 
        !is.na(HRTstartage_2) & !is.na(HRTendage_2) & between(age, HRTstartage_2, HRTendage_2) ~ 2, 
        !is.na(HRTstartage_3) & !is.na(HRTendage_3) & between(age, HRTstartage_3, HRTendage_3) ~ 3, 
        !is.na(HRTstartage_4) & !is.na(HRTendage_4) & between(age, HRTstartage_4, HRTendage_4) ~ 4, 
        TRUE ~ NA
      )
    ) |>
    rowwise() |>
    mutate(
    
      
      # HRT type
      HRTtype0_NA = NA,
      hrt_type = case_when(
        hrt != "current" | is.na(hrt) ~ NA,
        is.na( get(paste0("HRTtype0_", hrt_current_period))) ~ NA,
        get(paste0("HRTtype0_", hrt_current_period)) == "EandP" ~ 1,
        get(paste0("HRTtype0_", hrt_current_period)) == "Eonly" ~ 0,
        get(paste0("HRTtype0_", hrt_current_period)) == "HRTot" ~ NA,
        TRUE ~ NA
      )
      
    ) |>
    ungroup() |>
    mutate(
      
      # BMI
      bodysizebminow = case_when(
        bodysizebminow > 800 ~ NA,
        TRUE ~ bodysizebminow
      ),
      
      R2bodysizebmi = case_when(
        R2bodysizebmi > 800 ~ NA,
        TRUE ~ R2bodysizebmi
      ),
      
      R4bodysizebmi = case_when(
        R4bodysizebmi > 800 ~ NA,
        TRUE ~ R4bodysizebmi
      ),
      
      bmi_curc = case_when(
        age > R4Age & !is.na(R4bodysizebmi) ~ R4bodysizebmi,
        age > R2Age & !is.na(R2bodysizebmi) ~ R2bodysizebmi,
        TRUE ~ bodysizebminow
      ),

    ) |>
    select(TCode, age, age_at_menarche, age_first_birth, parity, oc_current, oc_ever, alcohol_intake, bbd, famhist, age_at_menopause, height, hrt, hrt_current_period, hrt_type, bmi_curc)
  
  # Now clean to iCARE standards
  df_iCARE <- df |>
    mutate(
      
      # Age
      age = floor(age),

      # Age at menarche
      age_at_menarche = case_when(
        is.na(age_at_menarche) ~ NA,
        age_at_menarche <= 10 ~ 1,
        age_at_menarche >= 16 ~ 7,
        TRUE ~ age_at_menarche-9
      ),
      # age_at_menarche=relevel(as.factor(as.character(age_at_menarche)), ref="4"),
      
      # Age at first birth
      age_first_birth = case_when(
        is.na(age_first_birth) ~ NA,
        age_first_birth < 20 ~ 1,
        age_first_birth < 25 ~ 2,
        age_first_birth < 30 ~ 3,
        TRUE ~ 4
      ),
      
      # Parity
      parity = case_when(
        parity == "0" ~ 0,
        parity == "1" ~ 1,
        parity == "2" ~ 2,
        TRUE ~ 3
      ),
      
      # Alcohol intake
      alcohol_intake = case_when(
        is.na(alcohol_intake) ~ NA,
        alcohol_intake == 0 ~ 1,
        alcohol_intake < 5 ~ 2,
        alcohol_intake < 15 ~ 3,
        alcohol_intake < 25 ~ 4,
        alcohol_intake < 35 ~ 5,
        alcohol_intake < 45 ~ 6,
        TRUE ~ 7
      ),
      
      # Age at menopause
      age_at_menopause = case_when(
        age < 50 ~ NA,
        is.na(age_at_menopause) ~ NA,
        age_at_menopause < 40 ~ 1,
        age_at_menopause < 45 ~ 2,
        age_at_menopause < 50 ~ 3,
        age_at_menopause < 55 ~ 4,
        TRUE ~ 5
      ),
      # age_at_menopause=ifelse(!is.na(age_at_menopause), relevel(as.factor(as.character(age_at_menopause)), ref="4"),NA),
      
      # Height
      height = height/10,
      
      # HRT
      hrt = case_when(
        hrt == "Never" ~ 0,
        hrt == "Former" ~ 1,
        hrt == "Current" ~ 2,
        TRUE ~ NA
      ),
      
      # BMI
      bmi_curc = case_when(
        is.na(bmi_curc) ~ NA,
        bmi_curc < 18.5 ~ 0,
        bmi_curc < 25 ~ 1,
        bmi_curc < 30 ~ 2,
        TRUE ~ 3
      ),
      # bmi_curc=ifelse(!is.na(bmi_curc), relevel(as.factor(as.character(bmi_curc)), ref="1"),NA),
      
    )
  
  # Split into multiple datasets
  df_iCARE_u50 <- df_iCARE |>
    filter(age < 50)
  
  df_iCARE_oe50 <- df_iCARE |>
    filter(age >= 50) |>
    mutate(bmi_curc = if_else(bmi_curc == 0, 1, bmi_curc))
  
  # Read in reference dataset for iCARE-Lit
  iCARE_Lit_ref_u50 <- read.csv("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/synthetic_population/populations/730919/iCARE_lit_u50.csv")
  iCARE_Lit_ref_oe50 <- read.csv("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/synthetic_population/populations/730919/iCARE_lit_oe50.csv")
  
  # Read in model dependencies
  load("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/data/icare-lit-r-dependencies/US_lit_lt50_inputs.Rda")
  load("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/data/icare-lit-r-dependencies/US_lit_ge50_inputs.Rda")
  
  # need to reorder names of the reference dataset
  colnames_in_order <- unlist(lapply(cov_info_lit_lt50, function(x){return(x$name)}))
  iCARE_Lit_ref_u50 <- iCARE_Lit_ref_u50[,colnames_in_order]
  colnames_in_order <- unlist(lapply(cov_info_lit_ge50, function(x){return(x$name)}))
  iCARE_Lit_ref_oe50 <- iCARE_Lit_ref_oe50[,colnames_in_order]
  
  # incidence rates
  source("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/repo_reuben/src/helper_functions/invasive_cancer_rates.R")
  bc_inc_UK <- suppressMessages(invasive_cancer_rates())
  # bc_inc_UK_rates <- bc_inc_UK$rate
  
  # competing mortality rates
  source("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/repo_reuben/src/helper_functions/competing_mortality.R")
  mort_UK <- suppressMessages(competing_mort_rates())
  
  # Run risk scores
  results_iCARE_lt50=computeAbsoluteRisk(model.formula = model.lit.lt50, model.cov.info = cov_info_lit_lt50, 
                                         model.snp.info = NULL, model.log.RR = beta_lit_lt50,
                                         model.ref.dataset = iCARE_Lit_ref_u50,
                                         model.ref.dataset.weights = NULL,
                                         model.disease.incidence.rates=bc_inc_UK,
                                         model.competing.incidence.rates = mort_UK,
                                         model.bin.fh.name = "famhist", n.imp = 5,
                                         apply.age.start=df_iCARE_u50$age, apply.age.interval.length=5,
                                         apply.cov.profile  = as.data.frame(df_iCARE_u50[, names(iCARE_Lit_ref_u50)]),
                                         apply.snp.profile = NULL,
                                         use.c.code = 1,  return.lp = TRUE, 
                                         return.refs.risk = TRUE)
  
  results_iCARE_ge50=computeAbsoluteRisk(model.formula = model.lit.ge50, model.cov.info = cov_info_lit_ge50, 
                                         model.snp.info = NULL, model.log.RR = beta_lit_ge50,
                                         model.ref.dataset = iCARE_Lit_ref_oe50,
                                         model.ref.dataset.weights = NULL,
                                         model.disease.incidence.rates=bc_inc_UK,
                                         model.competing.incidence.rates = mort_UK,
                                         model.bin.fh.name = "famhist", n.imp = 5,
                                         apply.age.start=df_iCARE_oe50$age, apply.age.interval.length=5,
                                         apply.cov.profile  = as.data.frame(df_iCARE_oe50[, names(iCARE_Lit_ref_oe50)]), 
                                         apply.snp.profile = NULL,
                                         use.c.code = 1,  return.lp = TRUE, 
                                         return.refs.risk = TRUE)
  
  # Compile risk scores together
  risk_scores_u50 <- data.frame(TCode = df_iCARE_u50$TCode, iCARE_Lit_risk_5 = results_iCARE_lt50$risk)
  risk_scores_oe50 <- data.frame(TCode = df_iCARE_oe50$TCode, iCARE_Lit_risk_5 = results_iCARE_ge50$risk)
  risk_scores <- rbind(risk_scores_u50, risk_scores_oe50) |>
    rename(iCARE_Lit_risk_5 = Risk_Estimate)

  
  # Output scores
  return(list(data=df, scores=risk_scores))
  
  
  
  
  
}
