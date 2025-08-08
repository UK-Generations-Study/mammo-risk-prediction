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
			
	| Score   | C-index |
	|---------|---------|
	| GAIL    | 0.539 \(0.498 - 0.579\)  |
	| Cumulus | 0.541 \(0.474 - 0.666\)  |
	| Mirai   | 0.656 \(0.619 - 0.690\) |
	| Mirai \(residuals\) | 0.622 \(0.555 - 0.687\) | 
	
2. Correlation with Risk Factors:
	* Associations with MIRAI 5-year risk score (Strategy B, controls only):
	
	| Variable           | Test       | Estimate    | p-value |
	|--------------------|------------|-------------|---------|
	| study.entry.age    | lm slope   | 0.000233    | 0.074   |
	| cumulus_reading    | lm slope   | 0.000254    | 0.018   |
	| bodysizebminow     | lm slope   | -0.000116   | 0.624   |
	| meno_age_est       | lm slope   | 0.0000339   | 0.890   |
	| pregparity_binary  | lm slope   | 0.00233     | 0.471   |
	| ocever             | lm slope   | -0.00383    | 0.541   |
	| hrtever            | lm slope   | 0.00246     | 0.363   |
	
	* Associations with MIRAI 5-year risk score (Strategy B, controls only, adjusted by time from baseline to mammography study):

	| Variable           | Test     | Estimate    | p-value |
	|--------------------|----------|-------------|---------|
	| study.entry.age    | lm slope | 0.000204    | 0.111   |
	| cumulus_reading    | lm slope | 0.000242    | 0.0245  |
	| bodysizebminow     | lm slope | -0.000206   | 0.379   |
	| meno_age_est       | lm slope | 0.0000934   | 0.700   |
	| pregparity_binary  | lm slope | 0.00306     | 0.337   |
	| ocever             | lm slope | -0.00412    | 0.511   |
	| hrtever            | lm slope | 0.00251     | 0.344   |
