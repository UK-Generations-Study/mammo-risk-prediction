### UPDATED GAIL SCORE GENERATION ###

# This function is intended to take as input a list of TCodes with an associated list of age that consist of the start of the follow up time
# The input should be structured as the output from create_analytical_dataset()
# It will then output the GAIL risk scores

# Inputs:
#   df - dataset containing TCodes with the column name "TCode" and age of follow up start with the column name "study.entry.age"

GAIL_score_generation <- function(df, years){
  
  # Read in risk factor data
  data_rf <- load_RDS_data("v20230927", "RDSRiskFactors.csv") |>
    crosstable::remove_labels()

  # Clean df to generate GAIL scores
  df_gail <- df |>
    select(TCode, study.entry.age, study.exit.age) |>
    merge(data_rf, by = "TCode", all.x = T) |>
    mutate(
      
      # TCode
      TCode = TCode,
      
      # ID
      ID = row_number(),
      
      # Age
      T1 = study.entry.age,
      T2 = study.entry.age + years,
      
      # N_Biop
      # NOTE: Unclear whether this data has been updated - will check
      N_Biop = brbensurgbiopsyN,
      
      # HypPlas
      # NOTE: Currently do not believe we have information on this - will check
      HypPlas = 99,
      
      # AgeMen
      # NOTE: Unclear what to code people who are pre-menarche as
      AgeMen = case_when(
        menarcheage %in% c(888, 999) ~ 99,
        menarcheage == 777 ~ 99, # This needs to be checked
        TRUE ~ menarcheage
      ),
      
      # Age1st
      # NOTE: can move some 98 to 99 if we get information on claimed parity at the questionnaire before the fup start
      Age1st = time_length(interval(start = ADOB_F, end = pregdate_1_f), unit = "year"),
      Age1st = case_when(
        is.na(Age1st) ~ 98,
        Age1st > T1 ~ 98,
        TRUE ~ floor(Age1st)
      ),
      
      # N_Rels
      # IN DEVELOPMENT
      N_Rels = fambrcaN,
      
      # Race
      Race = case_when(
        ethnew5 == 1 ~ 1, # White
        ethnew5 == 2 ~ 2, # African-American
        ethnew5 == 3 ~ 11, # South Asian
        ethnew5 == 4 ~ 1, # Unknown/White NOTE: NEED TO CHECK THIS
        ethnew5 == 9 ~ 1, # Unknown/White NOTE: NEED TO CHECK THIS
        TRUE ~ NA
      ),
      
      .keep = "none"
      
    )
  
  # Generate GAIL scores
  print(recode.check(df_gail) |> filter(Error_Ind == 1))
  
  df <- df |>
    mutate(gail_score = absolute.risk(df_gail)) |>
    select(TCode, gail_score)
  
  # Output scores
  return(list(data=df_gail, scores=df))
  
  
  
  
  
}
