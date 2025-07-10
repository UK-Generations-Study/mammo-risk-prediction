
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


# ---------------------------------------------------------------
# 1. Cleaning helper
# ---------------------------------------------------------------
clean_risk_factors <- function(df) {
  df %>% 
    mutate(
      pregparity_binary = factor(!pregparitycnt %in% c(-1, 99)),
      bodysizebminow    = na_if(bodysizebminow, 999),
      menopausal        = factor(ifelse(R1menopause %in% c(1, 3), TRUE, 
                                        ifelse(R1menopause == 2, FALSE, NA))),
      hrtever           = ifelse(menopausal==T, hrtever, NA),
      hrtever           = factor(hrtever),
      ocever            = ifelse(menopausal==F, ocever, NA),
      ocever            = factor(ocever),
      meno_age_est      = ifelse(meno_age_est > df$study.entry.age, NA, meno_age_est),
      time_start_to_mammo = StudyDate_m - as.Date(fupca_start_F_study)
    )
}

# ---------------------------------------------------------------
# 2. Association-test helper
# ---------------------------------------------------------------
assoc_tests <- function(df, y, preds, time_adjust=T) {
  purrr::map_dfr(preds, function(v) {
  if(time_adjust)
    mod <- lm(df[[y]] ~ df[[v]] + df$time_start_to_mammo)
  else 
    mod <- lm(df[[y]] ~ df[[v]])
  tt  <- summary(mod)$coefficients[2, ]   # slope row
  tibble(variable  = v,
         test      = "lm slope",
         statistic = tt["Estimate"],
         p.value   = tt["Pr(>|t|)"])
  })
}

# ---------------------------------------------------------------
# 3. Main wrapper
# ---------------------------------------------------------------
plot_y_vs_all <- function(
    df,
    y           = "mirai_score_5y",
    predictors  = c(
      "study.entry.age",
      "cumulus_reading",
      "bodysizebminow",
      "meno_age_est",
      "pregparitycnt", 
      "ocever",
      "hrtever"
    )
) {
  # -- clean & select ------------------------------------------------------
  df  <- clean_risk_factors(df)
  
  preds <- predictors
  if ("pregparitycnt" %in% preds)
    preds[preds == "pregparitycnt"] <- "pregparity_binary"
  preds <- intersect(preds, names(df))
  
  # -- split for pivot -----------------------------------------------------
  cont_vars <- preds[sapply(df[preds], is.numeric)]
  cat_vars  <- setdiff(preds, cont_vars)
  
  cont_long <- df %>%
    select(all_of(c(y, cont_vars))) %>%
    pivot_longer(-all_of(y), names_to = "variable", values_to = "value") %>%
    mutate(var_type = "continuous", value = as.character(value))
  
  cat_long  <- df %>%
    select(all_of(c(y, cat_vars))) %>%
    pivot_longer(-all_of(y), names_to = "variable", values_to = "value") %>%
    mutate(var_type = "categorical", value = as.character(value))
  
  long_df <- bind_rows(cont_long, cat_long) %>%
    mutate(variable = factor(variable, levels = preds)) 
  
  # -- build plot ----------------------------------------------------------
  p <- ggplot(long_df, aes(y = .data[[y]])) +
    geom_boxplot(
      data  = subset(long_df, var_type == "categorical"),
      aes(x = value, group = value)
    ) +
    geom_point(
      data  = subset(long_df, var_type == "continuous"),
      aes(x = as.numeric(value)),
      alpha = 0.30
    ) +
    geom_smooth(
      data  = subset(long_df, var_type == "continuous"),
      aes(x = as.numeric(value)),
      method = "lm", se = FALSE, color = "blue"
    ) +
    facet_wrap(~ variable, scales = "free_x") +
    theme_minimal() +
    labs(
      x     = NULL,
      y     = y,
      title = paste(y, "vs risk factors")
    ) + theme(panel.border = element_rect(fill=NA, color='black', size=1))
  
  # -- run association tests ----------------------------------------------
  tests <- assoc_tests(df, y, preds)
  
  # -- return both ---------------------------------------------------------
  list(plot = p, tests = tests)
}


correlation <- plot_y_vs_all(study.data.strategyB%>% filter(case_control_status == 0))
print(correlation$plot)

# Association with BMI, after adjusting for density
study.data.strategyB.cleaned <- clean_risk_factors(study.data.strategyB)
bmi_model <- lm(mirai_score_5y ~ bodysizebminow + cumulus_reading, data=study.data.strategyB.cleaned)
bmi_meno_model <- lm(mirai_score_5y ~ bodysizebminow*menopausal + cumulus_reading, data=study.data.strategyB.cleaned)


# # Correlations between risk factors and Mirai score
# # Age at mammogram
# with(study.data.strategyB %>% filter(case_control_status == 0), plot(study.entry.age, mirai_score_5y))
# with(study.data.strategyB %>% filter(case_control_status == 0), cor(study.entry.age, mirai_score_5y))
# 
# # Cumulus score
# with(study.data.strategyB %>% filter(case_control_status == 0), plot(cumulus_reading, mirai_score_5y))
# with(study.data.strategyB %>% filter(case_control_status == 0, !is.na(cumulus_reading)), cor(cumulus_reading, mirai_score_5y))
