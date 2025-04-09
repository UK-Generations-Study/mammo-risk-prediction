print.GSicareValid <- function(x, ...) {
  
  args     <- x$input.args
  mformula <- args[["model.formula", exact=TRUE]]
  mf       <- paste(mformula)
  
  cat("\n")
  cat(paste("Dataset: ", args$dataset, "\n", sep=""))
  cat(paste("Model Name: ", args$model.name, "\n", sep=""))
  if(is.null(mformula)){
    cat("Model formula: Likely an additive SNP-only model\n")
  } else {
    cat(paste("Model Formula: ",mf[2],mf[1],mf[3], "\n", sep=" "))
  }
  timeframe <- x$Risk_Prediction_Interval
  cat(paste("Risk Prediction Interval: ",timeframe, "\n", sep=""))
  #cat("\n")
  observed.outcome <- x$Subject_Specific_Observed_Outcome
  cat(paste("Number of study subjects: "
            ,length(observed.outcome), "\n", sep=""))
  #cat("\n")
  cat(paste("Number of cases: ",sum(observed.outcome), "\n", sep=""))
  #cat("\n")
  followup <- x$Adjusted_Followup
  cat(paste("Follow-up time (years) [mean,range]: [",
            round(mean(followup),3),", (",
            round(range(followup)[1],3),",",
            round(range(followup)[2],3),")","]\n", sep=""))
  #cat("\n")
  study.entry.age <- args$study.data$study.entry.age
  cat(paste("Baseline age (years) [mean,range]: [", 
            round(mean(study.entry.age),3),", (",
            round(range(study.entry.age)[1],3),",",
            round(range(study.entry.age)[2],3),")","]\n", sep=""))
  cat("\n")
  cat("Absolute Risk Calibration")
  print(x$Hosmer_Lemeshow_Results)
  #cat("\n")
  cat("Relative Risk Calibration")
  print(x$RR_test_result)
  #cat("\n")
  cat("Model Discrimination\n")
  cat(paste("Estimate of AUC (linear predictor): ", round(x$AUC.lp,3), "\n", sep=""))
  y <- x$CI_AUC.lp
  cat(paste("95% CI of AUC (linear predictor): (", round(y[1],3), ",", round(y[2],3), ")\n", sep=""))
  cat(paste("Estimate of AUC (absolute risk): ", round(x$AUC.ar,3), "\n", sep=""))
  y <- x$CI_AUC.ar
  cat(paste("95% CI of AUC (absolute risk): (", round(y[1],3), ",", round(y[2],3), ")\n", sep=""))
  cat("\n")
  cat("Overall Expected to Observed Ratio\n")
  exp_by_obs <- x$Overall_Expected_to_Observed_Ratio 
  cat(paste("Estimate: ",round(exp_by_obs,3), "\n", sep=""))
  CI_exp_by_obs <- x$CI_Overall_Expected_to_Observed_Ratio
  cat(paste("95% CI: ", "(", round(CI_exp_by_obs[1],3),
            ",", round(CI_exp_by_obs[2],3) ,")\n", sep=""))
  cat("\n")
  cat("Calibration Slope\n")
  cat(paste0("Estimate: ", round(unname(x$cal.slope$coefficients[2]),3), "\n"))
  cat(paste0("95% CI: (", round(unname(confint(x$cal.slope)[2,1]),3), ", ", round(unname(confint(x$cal.slope)[2,2]), 3), ")"))
  
  
  invisible(x)
  
}