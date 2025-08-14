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
library(gtsummary)
library(patchwork)
library(scales)


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

scores_and_rf_data <- read.csv(eligible_dicoms_fn) %>%
  append_event_data() %>% append_risk_scores(read.csv(eligible_dicoms_fn),return_gail_data=T)

study.data <- scores_and_rf_data$output %>%
  select('TCode', 'case_control_status', 'cumulus_reading', 'mirai_score_5y', 'gail_score',
         'study.entry.age', 'bodysizebminow') %>%
  left_join(scores_and_rf_data$gail_data, by='TCode')
            
###########
# Table 1 #
###########

# Demographics:
# study.entry.age

# Risk factors: # "T1", #HypPlas, "N_Biop", "AgeMen", "Age1st", "N_Rels", #Race
# T1: Age at mammogram
# HypPlas: History of atypical hyperplasia (0 = No, 1 = Yes, 99 = Missing)
# N_Biop: Number of breast biopsies with benign findings
# AgeMen: Age at menarche (Numeric, 99 = Missing)
# Age1st: Age at first pregnancy (Numeric, 98 = Missing)
# N_Rels: Number of first-degree relatives with breast cancer (Numeric, NA = Missing)
# Race: Race (White, African-American, Hispana/Latina, Asian-American, American Indian or Alaskan Native, Unknown)
# (1 = White, 2 = African-American,3 = Hispanic American, 4 = Other (Native American and Unknown), 5 = Hispanic American (Foreign-born),
# 6 = Chinese-American, 7: Japanese-American, 8: Filipino-American, 9: Hawaiian-American, 10 = Other Pacific Islander, 11 = Other Asian)

study.data <- study.data %>% mutate(
  case_control_status = factor(case_control_status, levels=c(0, 1), labels = c('Control', 'Case')),
  HypPlas = factor(HypPlas, levels=c(0, 1), labels = c('No', 'Yes')),
  N_Biop = factor(N_Biop),
  N_Rels = factor(N_Rels),
  AgeMen = ifelse(AgeMen != 99, AgeMen, NA),
  Age1st = ifelse(Age1st != 98, Age1st, NA),
  Race = factor(Race, levels = 1:11, labels = c(
    'White',
    'African-American',
    'Hispanic American',
    'Other (Native American and Unknown)',
    'Hispanic American (Foreign-born)',
    'Chinese-American',
    'Japanese-American',
    'Filipino-American',
    'Hawaiian-American',
    'Other Pacific Islander',
    'Other Asian'
  ))
)

# HypPlas not shown due to absence of data.
table.one <-
  study.data |>
  select(case_control_status, T1, N_Biop, AgeMen, Age1st, N_Rels, Race) |>
  tbl_summary(
    by = case_control_status,   # stratify by CC status
    type = list(
      T1 ~ "continuous",
      AgeMen ~ "continuous",
      Age1st ~ "continuous"
    ),
    label = list(
      T1 ~ "Age at mammogram (years)",
      #HypPlas ~ "History of atypical hyperplasia",
      N_Biop ~ "No. benign breast biopsies",
      AgeMen ~ "Age at menarche (years)",
      Age1st ~ "Age at first pregnancy (years)",
      N_Rels ~ "No. 1st-degree relatives with breast cancer",
      Race ~ "Race/ethnicity"
    ),
    statistic = list(
      all_continuous() ~ "{median} ({IQR})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 1,
    missing = "ifany"
  ) |>
  add_overall() |>
  add_n() |>
  modify_header(update = list(
    stat_1 ~ "**Controls, N = {n}**",
    stat_2 ~ "**Cases, N = {n}**",
    stat_0 ~ "**Overall, N = {N}**"
  ), label ~ "**Characteristic**") |>
  bold_labels()

# HTML
gt::gtsave(as_gt(table.one), filename = "../../results/tables/table_one.html")

# PNG
gt::gtsave(as_gt(table.one), filename = "../../results/tables/table_one.png", zoom = 2, vwidth = 1200)


################
# Violin plots #
################

cat_vars <- c('case_control_status', 'N_Biop', 'N_Rels', 'Race')
var_labels <- c(
  case_control_status = "Case/Control status",
  N_Biop              = "No. benign biopsies",
  N_Rels              = "No. FDRs with breast cancer",
  Race                = "Race/ethnicity"
)

# count non-missing observations per (variable, level)
violin_tagged <- violin_long %>%
  group_by(variable, level) %>%
  mutate(n_obs = sum(!is.na(mirai_score_5y))) %>%
  ungroup()

few_data  <- dplyr::filter(violin_tagged, n_obs < 5)
many_data <- dplyr::filter(violin_tagged, n_obs >= 5)

p <- ggplot(violin_tagged, aes(x = level, y = mirai_score_5y)) +
  geom_violin(
    data = many_data,
    fill = NA, linewidth = 0.6, trim = TRUE, draw_quantiles = 0.5
  ) + # Violins for >= 5 observations
  geom_point(
    data = few_data,
    shape = 21, fill = NA, color = "black", alpha = 0.7, size = 1.7, stroke = 1
  ) + # Points for < 5 observations
  facet_grid(
    ~ variable,
    scales = "free_x",
    space  = "free_x",
    labeller = as_labeller(var_labels)
  ) +
  labs(x = NULL, y = "Mirai 5-year score") +
  theme_minimal(base_size = 12) +
  scale_y_log10(
    breaks = c(0.01, 0.02, 0.05, 0.1, 0.2),
    labels = scales::label_number(accuracy = 0.001, trim = TRUE)
  ) +
  theme(
    panel.spacing = unit(1, "lines"),
    panel.border  = element_rect(color = "black", fill = NA, size = 1),
    strip.background = element_rect(color = "black", size = 1),
    panel.grid.major.x = element_blank(),
    strip.placement = "outside",
    strip.text.x = element_text(face = "bold"),
    axis.text.x = element_text(angle = 30, hjust = 1),
    axis.title.y = element_text(margin = margin(r = 14))
  )

# PNG
ggsave(
  filename = "../../results/plots/rf_distr.png",
  plot     = p,
  width    = 10, height = 5, units = "in", dpi = 300,
  bg       = "white"
)

# SVG
ggsave(
  filename = "../../results/plots/violin_plot.svg",
  plot     = p,
  width    = 10, height = 5, units = "in",
  bg       = "transparent"
)
