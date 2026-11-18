# Mammography AI Breast Cancer Risk Stratification in a UK Population


<p><a href="https://github.com/UK-Generations-Study/mammo-risk-prediction/blob/main/README.md">← Back to repository README</a></p>

## Analysis

### Figure 1

Distribution of 5-year Mirai AI-risk score for 241 breast cancer cases
and 369 controls, and risk factors in the Gail model and Cumulus®
percent mammographic density (PD) among controls. P-values are from
mutually adjusted linear regression models with logit-transformed Mirai
risk as the outcome. Abbreviations: BC – breast cancer.

![](analysis_files/figure-commonmark/unnamed-chunk-11-1.png)

### Table 1

Characteristics of breast cancer cases and controls in the study sample.
Abbreviations: BC – breast cancer, IQR – interquartile range.

| **Characteristic** | **Controls, N = 369** | **Cases, N = 241** |
|:---|:--:|:--:|
| **Age at mammogram (years), Median (IQR)** | 63.6 (56.3-68.7) | 61.1 (54.9-65.9) |
| **Mammography device used** |  |  |
| Lorad Selenia | 228 (62%) | 168 (70%) |
| Selenia Dimensions | 141 (38%) | 73 (30%) |
| **Race/ethnicity** |  |  |
| White | 365 (99%) | 238 (99%) |
| Non-white | 4 (1.1%) | 3 (1.2%) |
| **Age at menarche (years), Median (IQR)** | 13.0 (11.0-14.0) | 12.0 (11.0-13.0) |
| Unknown | 40 | 27 |
| **Age at first live birth (years)** |  |  |
| 24-25 | 65 (18%) | 38 (16%) |
| 26-29 | 83 (23%) | 45 (19%) |
| 30+ | 94 (26%) | 84 (35%) |
| \<24 | 78 (21%) | 42 (18%) |
| Nulliparous | 45 (12%) | 30 (13%) |
| Unknown | 4 | 2 |
| **No. benign breast biopsies** |  |  |
| 0 | 359 (97%) | 225 (93%) |
| 1+ | 10 (2.7%) | 16 (6.6%) |
| **No. 1st-degree relatives with breast cancer** |  |  |
| 0 | 314 (85%) | 186 (77%) |
| 1+ | 55 (15%) | 55 (23%) |
| **Mirai 5-year absolute risk (%), Median (IQR)** | 1.6 (1.3-2.2) | 2.5 (2.0-5.3) |
| **Gail 5-year absolute risk (%), Median (IQR)** | 1.7 (1.4-2.0) | 1.7 (1.4-2.2) |
| **Percent breast density (%), Median (IQR)** | 12.4 (6.9-20.8) | 16.1 (8.8-23.9) |
| Unknown | 226 | 147 |
| **Age at BC diagnosis (years), Median (IQR)** | \- | 64.1 (57.9-69.1) |
| **Time from mammogram to BC diagnosis (years), Median (IQR)** | \- | 2.9 (2.1-3.1) |
| **Cancer type** |  |  |
| Invasive | \- | 189 (78%) |
| DCIS | \- | 52 (22%) |
| **ER status** |  |  |
| Positive | \- | 138 (80%) |
| Negative | \- | 34 (20%) |
| Unknown | 0 | 69 |

### Table 2

Associations between Mirai, Gail and percent mammographic density (PD)
with breast cancer risk and risk discrimination. ORs are reported per SD
of the logit-transformed predictor and are adjusted for age at
mammography and matching factors. In combined models, ORs are mutually
adjusted for the other predictor. Relative risk calibration slope is
presented for absolute risk scores. All model discrimination estimates
were assessed through five-fold cross-validation for comparability.

| Model | Cases/Controls | Mirai | Gail | PD | AUC (95% CI) | Calibration Slope (95% CI) |
|:---|:---|:---|:---|:---|:---|:---|
| Model 1 | 241/369 | 2.84 (2.26, 3.76) | \- | \- | 0.74 (0.71, 0.79) | 1.75 (1.31, 2.24) |
| Model 2 | 241/369 | \- | 1.30 (1.10, 1.55) | \- | 0.56 (0.52, 0.62) | 1.24 (0.51, 2.01) |
| Model 4 | 241/369 | 2.81 (2.23, 3.74) | 1.22 (1.01, 1.49) | \- | 0.74 (0.71, 0.79) | \- |
| Model 1 | 94/143 | 2.20 (1.57, 3.43) | \- | \- | 0.68 (0.59, 0.74) | 1.19 (0.22, 2.37) |
| Model 2 | 94/143 | \- | 1.27 (0.98, 1.66) | \- | 0.56 (0.43, 0.65) | \- |
| Model 3 | 94/143 | \- | \- | 1.12 (0.95, 1.35) | 0.56 (0.41, 0.63) | \- |
| Model 4 | 94/143 | 2.22 (1.59, 3.52) | 1.29 (0.98, 1.72) | \- | 0.66 (0.59, 0.74) | \- |
| Model 5 | 94/143 | 2.16 (1.54, 3.44) | \- | 1.04 (0.86, 1.26) | 0.67 (0.58, 0.74) | \- |
| Model 6 | 94/143 | \- | 1.26 (0.97, 1.65) | 1.11 (0.93, 1.33) | 0.56 (0.45, 0.66) | \- |
| Model 7 | 94/143 | 2.20 (1.56, 3.56) | 1.28 (0.97, 1.73) | 1.02 (0.84, 1.24) | 0.65 (0.58, 0.74) | \- |

## Supplementary Material

### Supplementary Table 1

Associations of traditional breast cancer risk factors and Cumulus®
percent mammographic density (PD) with 5-year Mirai risk among 369
controls. Multivariable estimates (beta) are mutually adjusted for the
risk factors shown, with indicator variables to handle missingness.
Mirai risk score was logit-transformed before analysis. Abbreviations:
BC – breast cancer.

| **Risk Factor** | **Univariable Beta (95% CI)** | **Univariable P Value** | **Multivariable Beta (95% CI)** | **Multivariable P Value** |
|:---|:--:|:--:|:--:|:--:|
| Age at mammogram (years) | 0.01 (0.00, 0.02) | 0.008 | 0.01 (0.00, 0.02) | 0.007 |
| No. breast biopsies | -0.00 (-0.32, 0.31) | 0.977 | -0.08 (-0.39, 0.23) | 0.611 |
| Age at menarche (years) | 0.01 (-0.03, 0.05) | 0.643 | 0.00 (-0.03, 0.04) | 0.884 |
| Parity | 0.12 (-0.03, 0.28) | 0.129 | 0.25 (-0.07, 0.58) | 0.125 |
| Age at first birth (years) | -0.00 (-0.01, 0.01) | 0.512 | -0.01 (-0.02, 0.01) | 0.314 |
| Family history of BC | 0.13 (-0.02, 0.27) | 0.083 | 0.12 (-0.02, 0.26) | 0.096 |
| Percent breast density | 0.01 (0.01, 0.02) | \<0.001 | 0.02 (0.01, 0.02) | \<0.001 |

### Supplementary Table 2

Discrimination of Mirai and Gail risk scores according to different
prediction horizons.

| years | GAIL              | Mirai             |
|:------|:------------------|:------------------|
| 1     | 0.58 (0.53, 0.62) | 0.76 (0.72, 0.80) |
| 2     | 0.57 (0.53, 0.62) | 0.76 (0.72, 0.80) |
| 3     | 0.57 (0.52, 0.62) | 0.76 (0.72, 0.79) |
| 4     | 0.57 (0.52, 0.61) | 0.75 (0.71, 0.79) |
| 5     | 0.57 (0.52, 0.61) | 0.75 (0.71, 0.79) |

### Supplementary Table 3

Breast cancer diagnosis status and time from index mammogram to
diagnosis among cases and controls. Follow-up defined as the time from
entry to the study to December 2022 for participants residing in England
and the date of fourth follow-up questionnaire for all other
participants.

| **Characteristic** | **N** | **Controls, N = 369** | **Cases, N = 241** |
|:---|:--:|:--:|:--:|
| **Time from mammogram to BC diagnosis (years)** | 610 |  |  |
| \<=5 years |  | 8 (2.2%) | 221 (92%) |
| \>5 years |  | 5 (1.4%) | 20 (8.3%) |
| Control |  | 356 (96%) | 0 (0%) |
