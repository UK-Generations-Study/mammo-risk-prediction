# Mammography Risk Prediction

## Setup
* Have received digital mammograms from a subset of the Generations Study (GS).
* MIRAI takes as input digital mammograms and outputs a 1-, 2-, 3-, 4-, and 5-year risk.
* Objective is to compare the discrimination of MIRAI with standard breast density measures (Cumulus), as well as a standard risk model using risk factor information (GAIL).

## Study Population
* Subset of GS that has a valid mammography study. The criteria for a valid mammography study are:
	* Processed digital mammograms for all 4 standard views (LMLO, LCC, RCC, RMLO)
	* No prior history of breast cancer
	* Participant does not die in the year proceeding the mammography study
	* Mammography study was conducted before the end of follow up 
* If a mammography study had more than one mammographic image of the same view, only one was kept with random selection.
* Per participant, the latest mammography study performed more than one year before the date of diagnosis was selected.

## Plan of Analysis
* Risk scores
	* MIRAI scores calculated using latest valid mammography study as described above. The score for a 5-year risk will be used in discrimination analysis
	* Calculate GAIL scores using data up to the date of the mammogram
	* Use Cumulus scores from the date of the mammogram used to calculate MIRAI scores
	* As an estimate of the Mirai risk score excluding density information, the residuals were taken from a model fitting Cumulus readings onto Mirai 5yr risk
* Discrimination analysis
	* To evaluate discrimination of the scores, we will calculate the concordance index (C-index) of the scores with right-censoring at 5 years, end of follow-up, or at event, whichever comes first.
* Correlation with known risk factors
	* We assessed the association between MIRAI 5-year risk scores and established breast cancer risk factors using linear models.
	* Risk factors included:
		- Age at mammography study
		- Cumulus density reading
		- History of atypical hyperplasia (No, Yes)
		- Number of breast biopsies with benign findings
		- Age at menarche
		- Age at first pregnancy
		- Number of first-degree relatives with breast cancer
		- Race (White, African-American, Hispanic American, Other (Native American and Unknown), Hispanic American (Foreign-born), Chinese-American, Japanese-American, Filipino-American, Hawaiian-American, Other Pacific Islander, Other Asian)
		
## Data description
 ### Baseline characteristics
 <a href="results/tables/table_one.png">
   <img src="results/tables/table_one.png" alt="Table 1 — Baseline characteristics" width="600">
 </a>

 ### Risk factor distributions
 <a href="results/plots/rf_distr.png">
   <img src="results/plots/rf_distr.png" alt="Risk factor distributions" width="600">
 </a>
	
## Results
1. Discrimination performance
	* 615 eligible participants
		* 611 were available for analysis (4 excluded due to corrupted dicom or opt-out)
	
	### A. Complete Case Analysis (n = 611)

	| Score              | C-index                        |
	|--------------------|---------------------------------|
	| GAIL               | 0.535 (0.493 – 0.576)           |
	| iCARE-Lit (5-year) | 0.537 (0.497 – 0.580)           |
	| Mirai (5-year)     | 0.695 (0.660 – 0.730)           |

	### B. Subset with Cumulus Reading (n = 236)

	| Score                         | C-index                        |
	|-------------------------------|---------------------------------|
	| GAIL                          | 0.534 (0.470 – 0.597)           |
	| iCARE-Lit (5-year)            | 0.494 (0.430 – 0.561)           |
	| Mirai (5-year)                | 0.649 (0.591 – 0.707)           |
	| Cumulus                       | 0.552 (0.489 – 0.617)           |
	| Mirai residuals     (5-year)  | 0.640 (0.581 – 0.699)           |
	
2. Correlation with Risk Factors  
	### Univariable: Associations with MIRAI 5-year risk score (controls only):

	| Variable        | p-value |
	|-----------------|---------|
	| Age              | 0.0874  |
	| Number of biopsies          | 0.720   |
	| Age at menopause          | 0.770   |
	| Age at 1st birth          | 0.811   |
	| Number of relatives with breast cancer          | 0.0878  |
	| Cumulus reading | **0.000183** |

	### Multivariable: Associations with MIRAI 5-year risk score (controls only):

	| Variable            | p-value |
	|---------------------|---------|
	| Age                  | 0.0555  |
	| Number of biopsies             | 0.4314  |
	| Age at menopause              | 0.5168  |
	| Age at 1st birth              | 0.5711  |
	| Number of relatives with breast cancer              | 0.0797  |
	| Cumulus reading     | **0.00142** |
