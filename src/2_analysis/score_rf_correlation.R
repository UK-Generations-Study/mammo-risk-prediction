
library(ggplot2)
library(dplyr)
library(readr)
library(sqldf)
library(stringr)
library(lubridate)
library(gt)
library(pROC)
library(crosstable)
library(readxl)
library(Hmisc)
library(nftbart)
library(BCRA) # GAIL SCORE
library(GGally)
library(purrr)
library(broom)


##################
## LOADING DATA ##
##################


## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")

# Defining population: Eligible DICOM UIDS
eligible_dicom <- list()
eligible_dicom[["A"]] <- read.csv("../../../data/eligible_dicomuids_strategyA.csv")
eligible_dicom[["B"]] <- read.csv("../../../data/eligible_dicomuids_strategyB.csv")

# Mammo images
data_images <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoImages_v1.csv")

# Defining population: determine follow-up start date (date of mammogram)
data_images_dates_strategyA <- data_images |>
  filter(SOPInstanceUID %in% eligible_dicom[["A"]]$SOPInstanceUID) |>
  group_by(TCode) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

data_images_dates_strategyB <- data_images |>
  filter(SOPInstanceUID %in% eligible_dicom[["B"]]$SOPInstanceUID) |>
  group_by(TCode) |>
  summarise(StudyDate_m = as.Date(unique(StudyDate_m), format = "%d/%m/%Y")) |>
  ungroup()

# Risk scores: Mirai
load_mirai_score <- function(score_csv) {
  read.csv(score_csv) %>%
    rename(TCode = patient_exam_id, mirai_score_5y = X5_year_risk) %>% 
    mutate(TCode = gsub("([A-Za-z\\d]+)(\t0)", '\\1', TCode, perl=T)) %>%
    dplyr::select(TCode, mirai_score_5y)
}
risk_mirai_strategyA <- load_mirai_score("../../../output/mirai_scores_strategyA.csv")
risk_mirai_strategyB <- load_mirai_score("../../../output/mirai_scores_strategyB.csv")

# Risk scores: Cumulus
data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")
cumulus_scores_strategyA <- data_cumulus |>
  filter(SOPInstanceUID %in% eligible_dicom[["A"]]$SOPInstanceUID) |>
  filter(Reader_ID != "JW") |>
  group_by(TCode) |>
  summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))
cumulus_scores_strategyB <- data_cumulus |>
  filter(SOPInstanceUID %in% eligible_dicom[["B"]]$SOPInstanceUID) |>
  filter(Reader_ID != "JW") |>
  group_by(TCode) |>
  summarise(cumulus_reading = mean(Cumulus_Reading, na.rm = T))

# Merge time-to-event, risk factors, and risk scores
study.data.strategyA <- data_images_dates_strategyA |>
  do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m")) |>
  merge(risk_mirai_strategyA, by='TCode') |> 
  merge(cumulus_scores_strategyA, by='TCode', all.x=T)

study.data.strategyB <- data_images_dates_strategyB |>
  do(create_analytical_dataset(., years = NA, cancer = "breast", fup_start_date = "StudyDate_m")) |>
  merge(risk_mirai_strategyB, by='TCode') |> 
  merge(cumulus_scores_strategyB, by='TCode', all.x=T)

# Case/control status
study.data.strategyA <- study.data.strategyA |>
  mutate(
    
    case_control_status = case_when(
      time.of.onset > 5 | time.of.onset > (study.exit.age - study.entry.age) ~ 0,
      TRUE ~ 1
    ),
    
    #time.ci = pmin(time.of.onset, 5)
    time.ci = case_when(
      case_control_status == 0 ~ pmin(study.exit.age - study.entry.age, 5),
      TRUE ~ pmin(time.of.onset, 5)
    )
    
  )

study.data.strategyB <- study.data.strategyB |>
  mutate(
    
    case_control_status = case_when(
      time.of.onset > 5 | time.of.onset > (study.exit.age - study.entry.age) ~ 0,
      TRUE ~ 1
    ),
    
    #time.ci = pmin(time.of.onset, 5)
    time.ci = case_when(
      case_control_status == 0 ~ pmin(study.exit.age - study.entry.age, 5),
      TRUE ~ pmin(time.of.onset, 5)
    )
    
  )


##################
## CORRELATIONS ##
##################

clean_risk_factors <- function(df) {
  df %>%
    mutate(
      menopausal = factor(case_when(
        R1menopause %in% c(1, 3) ~ TRUE,
        R1menopause == 2 ~ FALSE,
        TRUE ~ NA
      )),
      pregparity_binary = factor(!pregparitycnt %in% c(-1, 99)),
      time_start_to_mammo = StudyDate_m - as.Date(fupca_start_F_study),
      
      bodysizebminow = na_if(bodysizebminow, 999),
      meno_age_est = if_else(meno_age_est > study.entry.age, NA_real_, meno_age_est),
      
      hrtever = factor(if_else(menopausal == TRUE, hrtever, NA_integer_)),
      ocever  = factor(if_else(menopausal == FALSE, ocever, NA_integer_))
    )
}


assoc_tests <- function(df, y, preds, time_adjust = TRUE) {
  map_dfr(preds, ~{
    predictor_name <- .x
    
    # Build the model formula
    formula_str <- if (time_adjust) {
      paste(y, "~", predictor_name, "+ time_start_to_mammo")
    } else {
      paste(y, "~", predictor_name)
    }
    
    lm(as.formula(formula_str), data = df) %>%
      tidy() %>%
      filter(startsWith(term, predictor_name)) %>%
      select(statistic = estimate, p.value) %>%
      mutate(
        variable = predictor_name,
        test = "lm",
        .before = 1
      )
  })
}


plot_y_vs_all <- function(
    df,
    y = "mirai_score_5y",
    predictors = c(
      "study.entry.age", "cumulus_reading", "bodysizebminow",
      "meno_age_est", "pregparitycnt", "ocever", "hrtever"
    ),
    time_adjust = F
) {
  df_clean <- clean_risk_factors(df)
  
  if ("pregparitycnt" %in% predictors) {
    predictors[predictors == "pregparitycnt"] <- "pregparity_binary"
  }
  preds <- intersect(predictors, names(df_clean))
  
  is_numeric_pred <- sapply(df_clean[preds], is.numeric)
  
  long_df <- bind_rows(
    df_clean %>% select(all_of(y), all_of(preds[is_numeric_pred])) %>%
      pivot_longer(-all_of(y), names_to = "variable", values_to = "value_num"),
    
    df_clean %>% select(all_of(y), all_of(preds[!is_numeric_pred])) %>%
      pivot_longer(-all_of(y), names_to = "variable", values_to = "value_cat")
  ) %>%
    mutate(variable = factor(variable, levels = preds))
  
  p <- ggplot(long_df, aes(y = .data[[y]])) +
    geom_boxplot(data = ~filter(., !is.na(value_cat)), aes(x = value_cat)) +
    geom_point(data = ~filter(., !is.na(value_num)), aes(x = value_num), alpha = 0.3) +
    geom_smooth(
      data = ~filter(., !is.na(value_num)), aes(x = value_num),
      method = "lm", se = FALSE, color = "blue"
    ) +
    facet_wrap(~ variable, scales = "free_x") +
    labs(
      x = "Risk Factor Value",
      y = y,
      title = paste(y, "vs. Risk Factors")
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.border = element_rect(color = "black", fill = NA, size = 0.5),
      strip.text = element_text(face = "bold")
    )
  
  tests <- assoc_tests(df_clean, y, preds, time_adjust = time_adjust)
  
  list(plot = p, tests = tests)
}


correlation <- plot_y_vs_all(study.data.strategyB%>% filter(case_control_status == 0), time_adjust = F)
print(correlation$tests)
correlation_timeadj <- plot_y_vs_all(study.data.strategyB%>% filter(case_control_status == 0), time_adjust = F)
print(correlation_timeadj$tests)

print(correlation$plot)

# # Association with BMI, after adjusting for density
# study.data.strategyB.cleaned <- clean_risk_factors(study.data.strategyB)
# bmi_model <- lm(mirai_score_5y ~ bodysizebminow + cumulus_reading, data=study.data.strategyB.cleaned)
# bmi_meno_model <- lm(mirai_score_5y ~ bodysizebminow*menopausal + cumulus_reading, data=study.data.strategyB.cleaned)
# 

# # Correlations between risk factors and Mirai score
# # Age at mammogram
# with(study.data.strategyB %>% filter(case_control_status == 0), plot(study.entry.age, mirai_score_5y))
# with(study.data.strategyB %>% filter(case_control_status == 0), cor(study.entry.age, mirai_score_5y))
# 
# # Cumulus score
# with(study.data.strategyB %>% filter(case_control_status == 0), plot(cumulus_reading, mirai_score_5y))
# with(study.data.strategyB %>% filter(case_control_status == 0, !is.na(cumulus_reading)), cor(cumulus_reading, mirai_score_5y))
