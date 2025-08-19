### UPDATED iCARE-Lit SCORE GENERATION ###

# This function is intended to take as input a list of TCodes with an associated list of age that consist of the start of the follow up time
# The input should be structured as the output from create_analytical_dataset()
# It will then output the iCARE-Lit 5 year absolute risk scores

# Inputs:
#   df - dataset containing TCodes with the column name "TCode" and age of follow up start with the column name "study.entry.age"

iCARE_Lit_score_generation <- function(df, model.args){
  
  # Read in risk factor data
  data_rf <- load_RDS_data("v20230927", "RDSRiskFactors.csv") |>
    crosstable::remove_labels()
  
  # Clean df to generate iCARE-Lit scores
  df_iCARE <- df |>
    select(TCode, study.entry.age, study.exit.age) |>
    merge(data_rf, by = "TCode", all.x = T) |>
    mutate(
      
      # TCode
      TCode = TCode,
      
      # Age
      age = study.entry.age,
      
      # Age at menarche
      age_at_menarche_cnt = case_when(
        menarcheage %in% c(888, 999) ~ NA,
        menarcheage == 777 ~ NA,
        menarcheage > age ~ NA,
        TRUE ~ menarcheage
      ),
      
      age_at_menarche = case_when(
        is.na(age_at_menarche_cnt) ~ NA,
        age_at_menarche_cnt <= 10 ~ 1,
        age_at_menarche_cnt >= 16 ~ 7,
        TRUE ~ age_at_menarche_cnt-9
      ),
      
      # Age at first birth
      age_first_birth = time_length(interval(start = ADOB_F, end = pregdate_1_f), unit = "year"),
      
      age_first_birth_cnt = case_when(
        is.na(age_first_birth) ~ NA,
        age_first_birth > age ~ NA,
        TRUE ~ age_first_birth
      ),
      
      age_first_birth = case_when(
        is.na(age_first_birth_cnt) ~ NA,
        age_first_birth_cnt < 20 ~ 1,
        age_first_birth_cnt < 25 ~ 2,
        age_first_birth_cnt < 30 ~ 3,
        TRUE ~ 4
      ),
      
      # Parity
      age_second_birth = time_length(interval(start = ADOB_F, end = pregdate_2_f), unit = "year"),
      age_third_birth = time_length(interval(start = ADOB_F, end = pregdate_3_f), unit = "year"),
      
      parity_cnt = case_when(
        is.na(age_first_birth) ~ "0",
        is.na(age_second_birth) | age_second_birth > age ~ "1",
        is.na(age_third_birth) | age_third_birth > age ~ "2",
        TRUE ~ ">=3"
      ),
      
      parity = case_when(
        is.na(age_first_birth) ~ 1,
        is.na(age_second_birth) | age_second_birth > age ~ 2,
        is.na(age_third_birth) | age_third_birth > age ~ 3,
        TRUE ~ 4
      ),
      
      # OC current
      oc_current = case_when(
        prod(is.na(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4)) == 1 ~ 0,
        !is.na(OCHTstartage_1) & !is.na(OCHTendage_1) & between(age, OCHTstartage_1, OCHTendage_1) ~ 1, 
        !is.na(OCHTstartage_2) & !is.na(OCHTendage_2) & between(age, OCHTstartage_2, OCHTendage_2) ~ 1, 
        !is.na(OCHTstartage_3) & !is.na(OCHTendage_3) & between(age, OCHTstartage_3, OCHTendage_3) ~ 1, 
        !is.na(OCHTstartage_4) & !is.na(OCHTendage_4) & between(age, OCHTstartage_4, OCHTendage_4) ~ 1, 
        TRUE ~ 0
      )
      
      # OC ever
      oc_ever = case_when(
        prod(is.na(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4)) == 1 ~ 0,
        pmin(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4, na.rm = T) < age ~ 1,
        TRUE ~ 0
      ),
      
      # Alcohol intake
      alcohol_intake = case_when(
        is.na(alcoholstartage) | is.na(alcoholstopage) ~ NA,
        alcoholstartage > age | alcoholstopage < age ~ 0,
        age > R4Age & R4age >= alcoholstartage & !is.na(R4alcoholunits) ~ R4alcoholunits,
        age > R2Age & R2age >= alcoholstartage & !is.na(R4alcoholunits) ~ R2alcoholunits,
        R1alcoholunits
      ),
      
      alcohol_intake_cnt = 8*alcohol_intake/7,
      
      alcohol_intake = case_when(
        is.na(alcohol_intake_cnt) ~ NA,
        alcohol_intake_cnt == 0 ~ 1,
        alcohol_intake_cnt < 5 ~ 2,
        alcohol_intake_cnt < 15 ~ 3,
        alcohol_intake_cnt < 25 ~ 4,
        alcohol_intake_cnt < 35 ~ 5,
        alcohol_intake_cnt < 45 ~ 6,
        TRUE ~ 7
      )
      
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
      age_at_menopause_cnt = case_when(
        meno_age == 999 ~ NA,
        meno_age == 777 ~ NA,
        meno_age > age ~ NA,
        TRUE ~ meno_age
      ),
      
      age_at_menopause = case_when(
        age < 50 ~ NA,
        is.na(age_at_menopause_cnt) ~ NA,
        age_at_menopause_cnt < 40 ~ 1,
        age_at_menopause_cnt < 45 ~ 2,
        age_at_menopause_cnt < 50 ~ 3,
        age_at_menopause_cnt < 55 ~ 4,
        TRUE ~ 5
      ),
      
      # Height
      # Believe this variable is not updated
      height = case_when(
        bodysizeht == 989 ~ NA,
        TRUE ~ bodysizeht
      ),
      
      # HRT
      hrt_cnt = case_when(
        prod(is.na(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4)) == 1 ~ "Never",
        !is.na(OCHTstartage_1) & !is.na(OCHTendage_1) & between(age, OCHTstartage_1, OCHTendage_1) ~ "Current", 
        !is.na(OCHTstartage_2) & !is.na(OCHTendage_2) & between(age, OCHTstartage_2, OCHTendage_2) ~ "Current", 
        !is.na(OCHTstartage_3) & !is.na(OCHTendage_3) & between(age, OCHTstartage_3, OCHTendage_3) ~ "Current", 
        !is.na(OCHTstartage_4) & !is.na(OCHTendage_4) & between(age, OCHTstartage_4, OCHTendage_4) ~ "Current", 
        !is.na(OCHTendage_1) & OCHTendage_1 < age & (prod(is.na(OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_2,OCHTendage_3,OCHTendage_4)) | pmin(OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_2,OCHTendage_3,OCHTendage_4, na.rm = T) > age) == "Former",
        !is.na(OCHTendage_2) & OCHTendage_2 < age & (prod(is.na(OCHTstartage_3, OCHTstartage_4,OCHTendage_3,OCHTendage_4)) | pmin(OCHTstartage_3, OCHTstartage_4,OCHTendage_3,OCHTendage_4, na.rm = T) > age) == "Former",
        !is.na(OCHTendage_3) & OCHTendage_3 < age & (prod(is.na(OCHTstartage_4, OCHTendage_4)) | pmin(OCHTstartage_4, OCHTendage_4, na.rm = T) > age) == "Former",
        !is.na(OCHTendage_4) & OCHTendage_4 < age == "Former",
        TRUE ~ NA
      ),
      
      hrt = case_when(
        hrt_cnt == "Never" ~ 0,
        hrt_cnt == "Former" ~ 1,
        hrt_cnt == "Current" ~ 2,
        TRUE ~ NA
      )
      
      hrt_current_period = case_when(
        prod(is.na(OCHTstartage_1, OCHTstartage_2, OCHTstartage_3, OCHTstartage_4,OCHTendage_1,OCHTendage_2,OCHTendage_3,OCHTendage_4)) == 1 ~ NA,
        !is.na(OCHTstartage_1) & !is.na(OCHTendage_1) & between(age, OCHTstartage_1, OCHTendage_1) ~ 1, 
        !is.na(OCHTstartage_2) & !is.na(OCHTendage_2) & between(age, OCHTstartage_2, OCHTendage_2) ~ 2, 
        !is.na(OCHTstartage_3) & !is.na(OCHTendage_3) & between(age, OCHTstartage_3, OCHTendage_3) ~ 3, 
        !is.na(OCHTstartage_4) & !is.na(OCHTendage_4) & between(age, OCHTstartage_4, OCHTendage_4) ~ 4, 
        TRUE ~ NA
      ),
      
      # HRT type
      hrt_type = case_when(
        hrt != "current" | is.na(hrt) ~ NA,
        is.na(!!sym(paste0("HRTtype0_", hrt_current_period))) ~ NA,
        !!sym(paste0("HRTtype0_", hrt_current_period)) == "EandP" ~ 1,
        !!sym(paste0("HRTtype0_", hrt_current_period)) == "Eonly" ~ 0,
        !!sym(paste0("HRTtype0_", hrt_current_period)) == "HRTot" ~ NA,
        TRUE ~ NA
      )
      
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
      
      bmi_cnt = case_when(
        age > R4Age & !is.na(R4bodysizebmi) ~ R4bodysizebmi,
        age > R2Age & !is.na(R2bodysizenbmi) ~ R2bodysizebmi,
        TRUE ~ bodysizebminow
      )
      
      bmi = case_when(
        is.na(bmi_cnt) ~ NA,
        bmi_cnt < 25 ~ 1,
        bmi_cnt < 30 ~ 2,
        TRUE ~ 3
      )

      .keep = "none"
      
    )
  
  
  
  # Run risk scores
  results_iCARE_lt50=computeAbsoluteRisk(model.formula = model.lit.lt50, model.cov.info = cov_info_lit_lt50, 
                                         model.snp.info = NULL, model.log.RR = beta_lit_lt50,
                                         model.ref.dataset = ref_lit_lt50_UK,
                                         model.ref.dataset.weights = NULL,
                                         model.disease.incidence.rates=bc_inc_UK,
                                         model.competing.incidence.rates = mort_UK,
                                         model.bin.fh.name = "famhist", n.imp = 5,
                                         apply.age.start=data_icare_lt50$age, apply.age.interval.length=5,
                                         apply.cov.profile  = data_icare_lt50[, names(ref_lit_lt50_UK)],
                                         apply.snp.profile = NULL,
                                         use.c.code = 1,  return.lp = TRUE, 
                                         return.refs.risk = TRUE)
  
  results_iCARE_ge50=computeAbsoluteRisk(model.formula = model.lit.ge50, model.cov.info = cov_info_lit_ge50, 
                                         model.snp.info = NULL, model.log.RR = beta_lit_ge50,
                                         model.ref.dataset = ref_lit_ge50_UK,
                                         model.ref.dataset.weights = NULL,
                                         model.disease.incidence.rates=bc_inc_UK,
                                         model.competing.incidence.rates = mort_UK,
                                         model.bin.fh.name = "famhist", n.imp = 5,
                                         apply.age.start=data_icare_ge50$age, apply.age.interval.length=5,
                                         apply.cov.profile  = data_icare_ge50[, names(ref_lit_ge50_UK)], 
                                         apply.snp.profile = NULL,
                                         use.c.code = 1,  return.lp = TRUE, 
                                         return.refs.risk = TRUE)

  
  # Output scores
  return(df)
  
  
  
  
  
}
