# Mammography AI Breast Cancer Risk Stratification in a UK Population

Code for:

> Adams D, Frost R, Jones M, Semenova E, Coulson P, Berrington de Gonzalez A, Garcia-Closas M.
> *Mammography AI Breast Cancer Risk Stratification in a UK Population*
> {Paper Source} {DOI}

## Overview

This repository contains the code for analysis of Mirai, an AI mammographic risk score in a case-control subset of the Breast Cancer Now Generations Study (BGS). Associations with breast cancer risk factors are invesitgated, and the discrimination abilities of Mirai are explored and compared alongside and in combination with the Gail clinical risk score and Cumulus percent breast density.

## Key Files
### [🔗 src/2_analysis/analysis.md]
* Reproduction of manuscript figures and tables

## Repository Structure

```text
mammo-risk-prediction/
├── logs/                         # Logs from code ran during analysis
├── results/                      # Folder with results from analysis
│   ├── plots/                    # Plots included in paper (.png)
│   ├── plots_svg/                # Plots included in paper (.svg)
│   └── tables/                   # Tables included in paper 
│
└── src/                          # Code used in the project
    ├── 0_population_definition/  # Definition of study sample
    ├── 1_score_generation/       # Generation of risk scores (Mirai, Gail, Cumulus)
    ├── 2_analysis/               # Analysis workflow
    │   └── analysis.qmd          # Recreation of figures and tables used in publication
    └── helper_functions/         # Helper functions used in full workflow
```

## Software Requirements

* R (version 4.4.1 or later recommended)

## Citation

If you use this repository in your work, please cite:

> Adams D, Frost R, Jones M, Semenova E, Coulson P, Berrington de Gonzalez A, Garcia-Closas M.
> *mammo-risk-prediction*.
> (2026).
> {ZENODO DOI}

## License

This project is licensed under the XXX License.
