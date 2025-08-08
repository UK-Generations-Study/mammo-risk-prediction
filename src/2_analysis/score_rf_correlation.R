library(ggplot2)
library(dplyr)
library(readr)
library(tidyr)
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


################
# LOADING DATA #
################

## Set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

## Functions
source("../helper_functions/create_analytical_dataset.R")
source("../helper_functions/Load_RDS_data.R")
source("../1_score_generation/GAIL_score_generation.R")
source("../helper_functions/append_event_and_risk.R")

# Defining population: Eligible DICOM UIDS
eligible_dicoms_fn <- "../../../data/eligible_dicomuids_strategyB.csv"

study.data <- read.csv(eligible_dicoms_fn) %>%
  append_event_data() %>% append_risk_scores()

###############
# HELPER FXNS #
###############

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
      # ocever  = factor(if_else(menopausal == FALSE, ocever, NA_integer_))
      ocever  = factor(ocever)
    )
}

assoc_tests <- function(df, y, preds, time_adjust = TRUE, multivariable = FALSE) {
  if(!multivariable) {
    map_dfr(preds, ~{
      predictor_name <- .x
      formula_str <- if (time_adjust) {
        paste(y, "~", predictor_name, "+ time_start_to_mammo")
      } else {
        paste('qlogis(',y,')', "~", predictor_name)
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
  } else {
    
  }
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


############################
# Univariable correlations #
############################

correlation <- plot_y_vs_all(study.data %>% filter(case_control_status == 0), time_adjust = F)
print(correlation$tests)
print(correlation$plot)

# Time-adjusted
correlation_timeadj <- plot_y_vs_all(study.data %>% filter(case_control_status == 0), time_adjust = T)
print(correlation_timeadj$tests)


##############################
# Multivariable correlations #
##############################

study.data.cleaned <- clean_risk_factors(study.data)# |> filter(!is.na(cumulus_reading))
preds <- c(
  "study.entry.age","bodysizebminow",  "cumulus_reading",
  "meno_age_est", "pregparity_binary", "ocever", "hrtever"
)
study.data.cleaned <- study.data.cleaned |>
  mutate(across(all_of(preds),
                ~ ifelse(is.na(.), 1, 0),
                .names = "{.col}_NA")) %>%
  mutate(
    across(all_of(preds), ~ {
      if (is.factor(.)) {
        addNA(.)
      } else {
        replace(., is.na(.), 0)
      }
    })
  )

non_factor_preds <- preds[!sapply(study.data.cleaned[preds], is.factor)]
na_cols <- paste0(non_factor_preds, "_NA")
all_preds <- c(preds, na_cols)
formula_str <- paste(all_preds, collapse = "+")
summary(lm(as.formula(paste('qlogis(mirai_score_5y)', "~", formula_str)), data=study.data.cleaned))


# Investigating significance of missing Cumulus reading:
summary(lm(as.formula(paste('qlogis(mirai_score_5y)', "~", 'cumulus_reading_NA')), data=study.data.cleaned))
summary(lm(qlogis(mirai_score_5y) ~ paste0(cumulus_reading_NA, "_", case_control_status), data = study.data.cleaned))
summary(lm(study.entry.age ~ cumulus_reading_NA, data = study.data.cleaned))
