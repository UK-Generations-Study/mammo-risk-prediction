### iCARE VALIDATION AND PLOTTING ###

# This function is for validating and plotting validation of invasive breast cancer risk models using iCARE

# Inputs:
#   study.data - dataset containing needed info. absolute risk for year x should have the name absrisk_x and relative risk should be relrisk.
#   years - number of years the validation takes place over. If this is NA then the absolute risk will be interpreted as an absolute risk over the follow up time given. The risk used in this case should be called absrisk_cen
#   dataset_name
#   model_name
#   filepath - filepath for the output of the plot
#   output - whether to output validation summary to the markdown/script
#   decile.variable - whether to use linear.predictor or absolute.risk


# Function
iCARE_validate_and_plot <- function(study.data, years = NA, filepath = NA, dataset_name = "GS", model_name = "BC Model", output = F, decile.variable = "linear.predictor"){
  
  # Import relevant iCARE plotting functions
  source("C:/Users/rfrost/OneDrive - The Institute of Cancer Research/Documents/Analysis/Functions/iCARE Functions/GS_ModelValidation.R")
  source("C:/Users/rfrost/OneDrive - The Institute of Cancer Research/Documents/Analysis/Functions/iCARE Functions/GS_plotModelValidation.R")
  source("C:/Users/rfrost/OneDrive - The Institute of Cancer Research/Documents/Analysis/Functions/iCARE Functions/print.GSicareValid.R")
  source("C:/Users/rfrost/OneDrive - The Institute of Cancer Research/Documents/Analysis/Functions/iCARE Functions/weighted.quantcut.R")
  source("C:/Users/rfrost/OneDrive - The Institute of Cancer Research/Documents/Analysis/Functions/invasive_cancer_rates.R")
  
  # Check relevant absrisk is in the data
  if(is.na(years) & !"absrisk_cen" %in% colnames(study.data)){
    stop(paste0("ERROR: absolute risk values to censoring age are not in the inputed dataset"))
  } else if(!is.na(years) & !paste0("absrisk_", years) %in% colnames(study.data)){
    stop(paste0("ERROR: ", years, " absolute risk values are not in the inputed dataset"))
  } else if(!is.na(years)){
    study.data$absrisk <- study.data[[paste0("absrisk_", years)]]
  } else {
    study.data$absrisk <- study.data$absrisk_cen
  }
  
  # Import population incidence rates for invasive breast cancer
  # # These rates are taken from CRUK (https://www.cancerresearchuk.org/health-professional/cancer-statistics/statistics-by-cancer-type/breast-cancer/incidence-invasive#heading-One)
  # ages <- seq(17.5, 102.5, by = 5)
  # incidence_rates <- c(0.1, 1.6, 11.5, 31.2, 65.8, 124.6, 214.8, 279.8, 285.5, 337.9, 412.3, 372.7, 403, 430.4, 447.7, 448.4, 448.4, 448.4)
  # incidence_rates <- incidence_rates/100000
  # model.disease.incidence.rates = data.frame(ages = ages, rate = incidence_rates)
  incidence_rates <- invasive_cancer_rates()
  
  # Run model validation
  if(!is.na(years)){
    # If over a specified time period
    ModelValidation <- GS_ModelValidation(study.data, 
                                                   total.followup.validation = FALSE,
                                                   predicted.risk = study.data$absrisk,
                                                   predicted.risk.interval = years, 
                                                   linear.predictor = study.data$lp, 
                                                   iCARE.model.object = 
                                                     list(model.formula = NULL,
                                                          model.cov.info = NULL,
                                                          model.snp.info = NULL,
                                                          model.log.RR = NULL,
                                                          model.ref.dataset = NULL,
                                                          model.ref.dataset.weights = NULL,
                                                          model.disease.incidence.rates = incidence_rates,
                                                          model.competing.incidence.rates = NULL,
                                                          model.bin.fh.name = NA,
                                                          apply.cov.profile  = NULL,
                                                          apply.snp.profile = NULL, 
                                                          n.imp = NULL, use.c.code = NULL,
                                                          return.lp = TRUE, 
                                                          return.refs.risk = TRUE),
                                                   number.of.percentiles = 10,
                                                   reference.entry.age = NULL, 
                                                   reference.exit.age = NULL,
                                                   predicted.risk.ref = NULL,
                                                   linear.predictor.ref = NULL,
                                                   linear.predictor.cutoffs = NULL,
                                                   decile.variable = decile.variable,
                                                   dataset = dataset_name, 
                                                   model.name = model_name)
  } else {
    # If over follow up length
    ModelValidation <- GS_ModelValidation(study.data, 
                                                   total.followup.validation = TRUE,
                                                   predicted.risk = study.data$absrisk,
                                                   predicted.risk.interval = NULL, 
                                                   linear.predictor = study.data$lp, 
                                                   iCARE.model.object = 
                                                     list(model.formula = NULL,
                                                          model.cov.info = NULL,
                                                          model.snp.info = NULL,
                                                          model.log.RR = NULL,
                                                          model.ref.dataset = NULL,
                                                          model.ref.dataset.weights = NULL,
                                                          model.disease.incidence.rates = incidence_rates,
                                                          model.competing.incidence.rates = NULL,
                                                          model.bin.fh.name = NA,
                                                          apply.cov.profile  = NULL,
                                                          apply.snp.profile = NULL, 
                                                          n.imp = NULL, use.c.code = NULL,
                                                          return.lp = TRUE, 
                                                          return.refs.risk = TRUE),
                                                   number.of.percentiles = 10,
                                                   reference.entry.age = NULL, 
                                                   reference.exit.age = NULL,
                                                   predicted.risk.ref = NULL,
                                                   linear.predictor.ref = NULL,
                                                   linear.predictor.cutoffs = NULL,
                                                   decile.variable = decile.variable,
                                                   dataset = dataset_name, 
                                                   model.name = model_name)
  }
  
  
  # If desired plot summary of validation
  if(output){
    print(ModelValidation)
  }
  
  # Need to remove NA and 0 values from Study Incidence Rates for the plot
  ModelValidation$Study_Incidence_Rate <- ModelValidation$Study_Incidence_Rate[!is.na(ModelValidation$Study_Incidence_Rate[,2]),]
  ModelValidation$Study_Incidence_Rate <- ModelValidation$Study_Incidence_Rate[ModelValidation$Study_Incidence_Rate[,2] > 0,]
  
  if(!is.na(filepath)){
    # Plot model validation and export to intended filepath
    png(filename = filepath, width = 1000, height = 600)
  }
    
  GS_plotModelValidation(study.data, ModelValidation,
                                   dataset=dataset_name,
                                   model.name=model_name,
                                   x.lim.absrisk = NULL,
                                   y.lim.absrisk = NULL, 
                                   x.lab.absrisk = "Expected Absolute Risk (%)", 
                                   y.lab.absrisk = "Observed Absolute Risk (%)", 
                                   x.lim.RR = NULL,
                                   y.lim.RR = NULL, 
                                   x.lab.RR = "Expected Relative Risk", 
                                   y.lab.RR = "Observed Relative Risk",
                                   risk.score.plot.kernel = "gaussian",
                                   risk.score.plot.bandwidth = "nrd0",
                                   risk.score.plot.percent.smooth = 50,
                                   decile.variable = decile.variable)
    
  if(!is.na(filepath)){
    invisible(capture.output(dev.off()))
  }
  
  
  # Return the model validation output
  return(ModelValidation)
  
  
}