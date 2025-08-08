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
	* To evaluate discrimination of the scores, we will calculate the concordance index (C-index) of the scores with right-censoring at 5 years.
* Correlation with known risk factors
	* We assessed the association between MIRAI 5-year risk scores and established breast cancer risk factors using linear models.
	* Risk factors included:
		- Age at mammography study
		- Cumulus density reading
		- BMI at baseline
		- Age at menopause
		- Parity status at baseline
		- Oral contraceptive use at baseline (among premenopausal women)
		- Hormone replacement therapy use at baseline (among postmenopausal women)
		
## Results
1. 
	* 615 eligible participants
		* 611 were available for analysis (4 excluded due to _need to complete_)
			* 423 participants (~69%) were missing a Cumulus density reading
	
	### A. Complete Case Analysis (n = 611)

	| Score           | C-index                        |
	|----------------|---------------------------------|
	| GAIL           | 0.539 (0.498 – 0.579)           |
	| Mirai (5-year) | 0.655 (0.620 – 0.690)           |

	### B. Subset with Cumulus Reading (n = 188)

	| Score           | C-index                        |
	|----------------|---------------------------------|
	| Cumulus        | 0.541 (0.472 – 0.610)           |
	| GAIL           | 0.529 (0.462 – 0.593)           |
	| Mirai (5-year) | 0.630 (0.566 – 0.693)           |
	
2. Correlation with Risk Factors:

	### Univariable: Associations with MIRAI 5-year risk score (controls only):
	
	| Variable           | Test | Estimate   | p-value |
	|--------------------|------|------------|---------|
	| study.entry.age    | lm   | 0.00801    | 0.0170  |
	| cumulus_reading    | lm   | 0.00779    | 0.00284 |
	| bodysizebminow     | lm   | -0.000740  | 0.905   |
	| meno_age_est       | lm   | 0.000619   | 0.921   |
	| pregparity_binary  | lm   | 0.0409     | 0.625   |
	| ocever             | lm   | -0.0481    | 0.527   |
	| hrtever            | lm   | 0.0448     | 0.497   |

	### Multivariable: Associations with MIRAI 5-year risk score (controls only):
	
	| Variable                | Estimate   | p-value   |
	|-------------------------|------------|-----------|
	| study.entry.age         | 0.008543   | 0.106751  |
	| cumulus_reading         | 0.008722   | 0.000348  |
	| bodysizebminow          | 0.014977   | 0.012955  |
	| meno_age_est            | 0.001707   | 0.790228  |
	| pregparity_binary       | 0.096926   | 0.228883  |
	| ocever                  | -0.031448  | 0.672083  |
	| hrtever                 | 0.048213   | 0.434621  |
	| hrteverNA               | 0.092853   | 0.285590  |
	| study.entry.age_NA      | NA         | NA        |
	| bodysizebminow_NA       | 0.462661   | 0.042469  |
	| cumulus_reading_NA      | 0.170572   | 0.015404  |
	| meno_age_est_NA         | 0.122369   | 0.719432  |
