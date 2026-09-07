### CUMULUS OR CHECKING ###

# Packages
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

# Read in Cumulus readings
data_cumulus <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoCumulus_v1.csv")

# Read in Set
data_set <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/CoreData/v20230927/RDSCCMammoSet_v1.csv")

# Read in function
source("//rds/data/DGE/DUDGE/INCANEPI/Generations/Projects/mammo_risk_prediction/mirai/repo_reuben/src/helper_functions/data_processing.R")


# Filter data_set to variables we need
data_set <- data_set |>
  select(SOPInstanceUID, CaseControlRequestStatus, MammoDate)

# Subset to analytical group
data_cumulus_analysis <- data_cumulus |>
  # Merge in data_set
  merge(data_set, by = "SOPInstanceUID") |>
  # Remvove JW
  filter(Reader_ID != "JW") |>
  # Take first mammographic study per individual
  mutate(MammoDate = as.Date(MammoDate, format = "%d/%m/%Y")) |>
  group_by(TCode) |>
  filter(MammoDate == first(MammoDate)) |>
  ungroup() |>
  # Take first mammogram when multiple per SOPInstance UID
  group_by(SOPInstanceUID) |>
  filter(row_number() == 1) |>
  ungroup() |>
  # Calculate mean density
  group_by(TCode) |>
  summarise(
    MammoDate = first(MammoDate),
    CaseControlRequestStatus = first(CaseControlRequestStatus),
    cumulus_reading = mean(Cumulus_Reading, na.rm = T)
  ) |>
  mutate(cc_status = if_else(CaseControlRequestStatus == 2, 0, 1))

# Make analytical dataset
data_analysis <- data_cumulus_analysis |>
  do(create_analytical_dataset(., years = NA, cancer = "all_breast", fup_start_date = "MammoDate"))

# Create matching variables

# Read in year of entry to study
year.entry <- read.csv("//rds/data/DGE/DUDGE/Shared/GENERATIONS/Event_Years/RDSTrueYear.csv") |>
  select(TCode, Entry)

# Get cancer-free time from study entry for those included
cancer.free.time <- data_analysis |>
  select(TCode) |>
  do(create_analytical_dataset(., cancer = "all_breast")) |>
  mutate(cancer.free.time = pmin(study.exit.age - study.entry.age, time.of.onset)) |>
  select(TCode, cancer.free.time)


data_analysis <- data_analysis |>
  merge(year.entry, by = "TCode") |>
  merge(cancer.free.time, by = "TCode") |>
  mutate(
    
    # Age at mammogram
    match.mammo.age = cut(study.entry.age, breaks = seq(10, 110, by = 5)),
    match.mammo.age = if_else(match.mammo.age == "(25,30]", "(30,35]", match.mammo.age),
    match.mammo.age = if_else(match.mammo.age == "(85,90]", "(80,85]", match.mammo.age),
    
    # Age at entry
    match.entry.age = cut(AgeatEntry, breaks = seq(10, 110, by = 5)),
    match.entry.age = if_else(match.entry.age == "(30,35]", "(35,40]", match.entry.age),
    
    # Ethnicity
    match.ethnicity = as.factor(if_else(ethnew5 == 1, 1, 0)),
    
    # Year of entry
    match.year.entry = case_when(
      Entry <= 2005 ~ "<=2005",
      Entry >= 2008 ~ ">=2008",
      TRUE ~ as.character(Entry)
    ),
    
    # Cancer free time from entry
    match.cancer.free.time = case_when(
      cancer.free.time < 10 ~ "[0,10)",
      cancer.free.time <13 ~ "[10,13)",
      TRUE ~ "[13,16)"
    )
    
  )


score <- "cumulus_reading"

# Fit model calculating score using matching variables
# Fitting model on controls that have the score measured
model1 <- lm(as.formula(paste0("qlogis(", score, "/100) ~ match.entry.age + match.ethnicity + match.year.entry + match.cancer.free.time + match.mammo.age")), data = data_analysis[!is.na(data_analysis[[score]]) & data_analysis$cc_status == 0,])

# Predict score on whole dataset
data_analysis$model1_pred <- NA
data_analysis$model1_pred[!is.na(data_analysis[[score]])] <- predict(model1, data_analysis[!is.na(data_analysis[[score]]),])

# Calculate residual
data_analysis$model1_res <- qlogis(data_analysis[[score]]/100) - data_analysis$model1_pred

# Seperate into quartiles
data_analysis$cumulus_quartile <- as.character(as.numeric(cut2(data_analysis$cumulus_reading, g = 4)))
data_analysis$cumulus_quartile_adj <- as.character(as.numeric(cut2(data_analysis$model1_res, g = 4)))

# Run model
model <- glm(cc_status ~ cumulus_quartile + match.entry.age + match.ethnicity + match.year.entry + match.cancer.free.time, data = data_analysis, family = "binomial")
# summary(model)
# model <- glm(cc_status ~ cumulus_quartile_adj, data = data_analysis, family = "binomial")
summary(model)

for(level in 1:4){
  
  if(level == 1){
    plot.data <- data.frame(level = 1, or = NA, or_lci = NA, or_uci = NA)
  } else {
    
    or <- exp(model$coefficients[names(model$coefficients) == paste0("cumulus_quartile", level)])
    
    or_lci <- unname(exp(confint(model)[rownames(confint(model)) == paste0("cumulus_quartile", level),]))[1]
    
    or_uci <- unname(exp(confint(model)[rownames(confint(model)) == paste0("cumulus_quartile", level),]))[2]
    
    plot.data[nrow(plot.data)+1,] <- c(level, or, or_lci, or_uci)
    
  }
  
}

plot <- ggplot(plot.data, aes(x = as.character(level), y = or)) + 
  geom_point() +
  geom_segment(x = 0, y = 1, xend = Inf, yend = 1, colour = "black", linetype = "dashed") +
  geom_errorbar(aes(ymin = or_lci, ymax = or_uci), width = 0.1) +
  theme_minimal() +
  geom_rect(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
            colour = "black", fill = NA, inherit.aes = FALSE) +
  labs(
    x = "Cumulus Quartile",
    y = "Odds Ratio"
  )

plot


## RANDOM SAMPLE

auc_list <- numeric(0)
or_list <- numeric(0)

for(i in 1:10000){
  
  data_analysis_temp <- data_analysis[sample(1:nrow(data_analysis), size = 283),]
  
  # Run model
  sd <- data_analysis_temp |>
    filter(cc_status == 0) |>
    pull(model1_res) |>
    sd()

  model <- data_analysis_temp |>
    mutate(model1_res_sd = model1_res/sd) |>
    glm(formula = cc_status ~ model1_res_sd, family = "binomial")
  summary(model)
  
  or_list[i] <- exp(summary(model)$coefficients[2,1])
  
  
  auc_list[i] <- suppressMessages(data_analysis_temp |> roc(cc_status, cumulus_reading, direction = "<") |> auc())
  # data_analysis_temp |> roc(cc_status, model1_res) |> ci.auc()
  
}

sum(or_list < 1.18)/10000
sum(auc_list < 0.55)/10000



# Seperate into quartiles
plot.data <- data.frame(rep = 0, level = 1, or = NA)
for(i in 1:1000){
  
  data_analysis_temp <- data_analysis[sample(1:nrow(data_analysis), size = 596),]
  
  data_analysis_temp$cumulus_quartile <- as.character(as.numeric(cut2(data_analysis_temp$cumulus_reading, g = 4)))
  data_analysis_temp$cumulus_quartile_adj <- as.character(as.numeric(cut2(data_analysis_temp$model1_res, g = 4)))
  
  # Run model
  model <- glm(cc_status ~ cumulus_quartile, data = data_analysis_temp, family = "binomial")
  # summary(model)
  # model <- glm(cc_status ~ cumulus_quartile_adj, data = data_analysis_temp, family = "binomial")

  for(level in 2:4){
      
    or <- exp(model$coefficients[names(model$coefficients) == paste0("cumulus_quartile", level)])
    
    plot.data[nrow(plot.data)+1,] <- c(i, level, or)
    
  }

}

for(i in 2:4){
  
  p <- plot.data |>
    filter(level == i) |>
    ggplot(aes(x = or)) +
    geom_histogram(bins = 20, fill = "white", colour = "black") +
    theme_minimal() +
    labs(
      title = i
    )
  
  plot.data |>
    filter(level == i) |>
    pull(or) |>
    quantile(c(0.025, 0.975)) |>
    print()
  
  
  
  print(p)
  
}


