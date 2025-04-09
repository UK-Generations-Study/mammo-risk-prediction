age_adjusted_plotModelValidation <- function (study.data, validation.results, dataset = "Example Dataset", 
          model.name = "Example Model", x.lim.absrisk = NULL, y.lim.absrisk = NULL, 
          x.lab.absrisk = "Expected Absolute Risk (%)", y.lab.absrisk = "Observed Absolute Risk (%)", 
          x.lim.RR = NULL, y.lim.RR = NULL, x.lab.RR = "Expected Relative Risk", 
          y.lab.RR = "Observed Relative Risk", risk.score.plot.kernel = "gaussian", 
          risk.score.plot.bandwidth = "nrd0", risk.score.plot.percent.smooth = 50) 
{
  
  ### READING IN CALIBRATION SLOPE ###
  
  cal.slope = validation.results$cal.slope
  
  cal.slope.est = unname(cal.slope$coefficients[2])
  cal.slope.lc = unname(confint(cal.slope)[2,1])
  cal.slope.uc = unname(confint(cal.slope)[2,2])
  
  ### END OF READING IN CALIBRATION SLOPE ###
  
  Category.Results = validation.results$Category_Results
  followup = validation.results$Adjusted_Followup
  observed.outcome = validation.results$Subject_Specific_Observed_Outcome
  linear.predictor = validation.results$Subject_Specific_Risk_Score
  model.disease.incidence.rates = validation.results$Population_Incidence_Rate
  timeframe = validation.results$Risk_Prediction_Interval
  ages = validation.results$Study_Incidence_Rate[, 1]
  study_incidence = validation.results$Study_Incidence_Rate[, 
                                                            2]
  study.entry.age = study.data$study.entry.age
  sampling.weights = study.data$sampling.weights
  if (is.null(sampling.weights)) 
    sampling.weights = rep(1, dim(study.data)[1])
  freq = 1/sampling.weights
  freq.cases = freq[observed.outcome == 1]
  freq.controls = freq[observed.outcome == 0]
  linear.predictor.cases = linear.predictor[observed.outcome == 
                                              1]
  linear.predictor.controls = linear.predictor[observed.outcome == 
                                                 0]
  observed.prob.cat = as.numeric(as.character(Category.Results$Observed_Absolute_Risk))
  predicted.prob.cat = as.numeric(as.character(Category.Results$Predicted_Absolute_Risk))
  observed.RR.cat = as.numeric(as.character(Category.Results$Observed_Relative_Risk))
  predicted.RR.cat = as.numeric(as.character(Category.Results$Predicted_Relative_Risk))
  upper.limit.absrisk.cat = as.numeric(as.character(Category.Results$CI_Absolute_Risk_Upper))
  lower.limit.absrisk.cat = as.numeric(as.character(Category.Results$CI_Absolute_Risk_Lower))
  upper.limit.RR.cat = as.numeric(as.character(Category.Results$CI_Relative_Risk_Upper))
  lower.limit.RR.cat = as.numeric(as.character(Category.Results$CI_Relative_Risk_Lower))
  chisq.absrisk = as.numeric(validation.results$Hosmer_Lemeshow_Results[["statistic"]])
  number.of.percentiles = as.numeric(validation.results$Hosmer_Lemeshow_Results[["parameter"]])
  PVAL_absrisk = as.numeric(validation.results$Hosmer_Lemeshow_Results[["p.value"]])
  chisq.logRR = as.numeric(validation.results$RR_test_result[["statistic"]])
  PVAL_logRR = as.numeric(validation.results$RR_test_result[["p.value"]])
  auc = validation.results$AUC
  upper.limit.auc = validation.results$CI_AUC[2]
  lower.limit.auc = validation.results$CI_AUC[1]
  
  auc.lps = validation.results$AUC.lps #####
  upper.limit.auc.lps = validation.results$CI_AUC.lps[2] #####
  lower.limit.auc.lps = validation.results$CI_AUC.lps[1] #####
  
  Overall.Expected.to.Observed.Ratio = validation.results$Overall_Expected_to_Observed_Ratio
  CI.Overall.Expected.to.Observed.Ratio = validation.results$CI_Overall_Expected_to_Observed_Ratio
  if (length(x.lim.absrisk) < 2) {
    x.lim.absrisk = c(min(lower.limit.absrisk.cat, predicted.prob.cat) * 
                        100, max(upper.limit.absrisk.cat, predicted.prob.cat) * 
                        100)
  }
  if (length(y.lim.absrisk) < 2) {
    y.lim.absrisk = c(min(lower.limit.absrisk.cat, predicted.prob.cat) * 
                        100, max(upper.limit.absrisk.cat, predicted.prob.cat) * 
                        100)
  }
  if (length(x.lim.RR) < 2) {
    x.lim.RR = c(min(lower.limit.RR.cat, predicted.RR.cat), 
                 max(upper.limit.RR.cat, predicted.RR.cat))
  }
  if (length(y.lim.RR) < 2) {
    y.lim.RR = c(min(lower.limit.RR.cat, predicted.RR.cat), 
                 max(upper.limit.RR.cat, predicted.RR.cat))
  }
  m <- rbind(c(1, 2), c(3, 4), c(5, 5))
  layout(m)
  oldpar = par(mar = rep(4, 4))
  # plotCI(predicted.prob.cat * 100, observed.prob.cat * 100, 
  #        ui = upper.limit.absrisk.cat * 100, li = lower.limit.absrisk.cat * 
  #          100, xlab = x.lab.absrisk, ylab = y.lab.absrisk, 
  #        xlim = c(0,4), ylim = c(0,4), col = "red", 
  #        pch = 16, pty = "s", cex.lab = 1.2)
  plotCI(predicted.prob.cat * 100, observed.prob.cat * 100, 
         ui = upper.limit.absrisk.cat * 100, li = lower.limit.absrisk.cat * 
           100, xlab = x.lab.absrisk, ylab = y.lab.absrisk, 
         xlim = x.lim.absrisk, ylim = y.lim.absrisk, col = "red", 
         pch = 16, pty = "s", cex.lab = 1.2)
  abline(0, 1, lty = 2, col = "black")
  mtext("Absolute Risk Calibration", side = 3, line = 1, font = 4)
  # plotCI(predicted.RR.cat, observed.RR.cat, ui = upper.limit.RR.cat, 
  #        li = lower.limit.RR.cat, xlab = x.lab.RR, ylab = y.lab.RR, 
  #        xlim = c(0,2.5), ylim = c(0,2.5), col = "red", pch = 16, 
  #        pty = "s", cex.lab = 1.2)
  plotCI(predicted.RR.cat, observed.RR.cat, ui = upper.limit.RR.cat, 
         li = lower.limit.RR.cat, xlab = x.lab.RR, ylab = y.lab.RR, 
         xlim = x.lim.RR, ylim = y.lim.RR, col = "red", pch = 16, 
         pty = "s", cex.lab = 1.2)
  abline(0, 1, lty = 2, col = "black")
  mtext("Relative Risk Calibration", side = 3, line = 1, font = 4)
  suppressWarnings(plot(density(linear.predictor.controls, bw = risk.score.plot.bandwidth, 
               kernel = risk.score.plot.kernel, weights = freq.controls/sum(freq.controls), 
               n = (risk.score.plot.percent.smooth/100) * length(linear.predictor.controls)), 
       xlim = c(min(density(linear.predictor.controls)$x, density(linear.predictor.cases)$x), 
                max(density(linear.predictor.controls)$x, density(linear.predictor.cases)$x)), 
       ylim = c(min(density(linear.predictor.controls)$y, density(linear.predictor.cases)$y), 
                max(density(linear.predictor.controls)$y, density(linear.predictor.cases)$y)), 
       main = "", xlab = "Risk Score", pty = "s", cex.lab = 1.2))
  suppressWarnings(lines(density(linear.predictor.cases, bw = risk.score.plot.bandwidth, 
                kernel = risk.score.plot.kernel, weights = freq.cases/sum(freq.cases), 
                n = (risk.score.plot.percent.smooth/100) * length(linear.predictor.controls)), 
        col = "red"))
  legend("topright", legend = c("Controls", "Cases"), col = c("black", 
                                                              "red"), lty = 1, cex = 0.75, y.intersp = 2, xjust = 0.5, 
         yjust = 0.5, x.intersp = 3, adj = c(0.3, 0.6))
  mtext("Discrimination", side = 3, line = 1, font = 4)
  suppressWarnings(plot(model.disease.incidence.rates[, 1], predict(loess(model.disease.incidence.rates[, 
                                                                                       2] ~ model.disease.incidence.rates[, 1])), log = "y", 
       type = "l", xlim = c(min(ages), max(ages)), ylim = c(min(model.disease.incidence.rates[, 
                                                                                                                   2], study_incidence) + 10^(-10), max(model.disease.incidence.rates[, 
                                                                                                                                                                                      2], study_incidence)), xlab = "Age (in years)", 
       ylab = "Incidence Rates", pty = "s", cex.lab = 1.2))
  lines(ages, study_incidence, col = "red")
  legend("bottomright", legend = c("Population", "Study"), 
         col = c("black", "red"), lty = 1, cex = 0.9, y.intersp = 2, 
         x.intersp = 3, adj = c(0.3, 0.6))
  mtext("Incidence Rates", side = 3, line = 1, font = 4)
  plot(c(0, 2), c(0, 2.4), xaxt = "n", yaxt = "n", bty = "n", 
       pch = "", ylab = "", xlab = "", pty = "s")
  text(x = 1, y = 2.3, paste("Dataset: ", dataset), cex = 1.3)
  text(x = 1, y = 2.05, paste("Model Name: ", model.name), cex = 1.3)
  text(x = 1, y = 1.8, paste("Risk Prediction Interval:",
                             timeframe), cex = 1.3)
  text(x = 1, y = 1.55, paste("Number of subjects (cases): ",
                             length(observed.outcome), "(", sum(observed.outcome),
                             ")"), cex = 1.3)
  text(x = 1, y = 1.3, paste("Follow-up time (years) [mean,range]: [", 
                             round(mean(followup), 3), ", (", round(range(followup)[1], 
                                                                    3), ",", round(range(followup)[2], 3), ")", " ]"), cex = 1.3)
  text(x = 1, y = 1.05, paste("Baseline age (years) [mean,range]: [", 
                           round(mean(study.entry.age), 3), ", (", round(range(study.entry.age)[1], 
                                                                         3), ",", round(range(study.entry.age)[2], 3), ")", 
                           " ]"), cex = 1.3)
  text(x = 1, y = 0.8, paste("E/O [Estimate, 95% CI]:", "[", 
                             round(Overall.Expected.to.Observed.Ratio, 3), ",", "(", 
                             round(CI.Overall.Expected.to.Observed.Ratio[1], 3), 
                             ",", round(CI.Overall.Expected.to.Observed.Ratio[2], 
                                        3), ")", "]"), cex = 1.3)
  
  
  text(x = 1, y = 0.55, paste("Calibration Slope [Estimate, 95% CI]:", "[", 
                             round(cal.slope.est, 3), ",", "(", 
                             round(cal.slope.lc, 3), 
                             ",", round(cal.slope.uc, 
                                        3), ")", "]"), cex = 1.3)
  
  text(x = 0.1, y = 1.8, "Absolute Risk Calibration", font = 2, cex = 1.3)
  text(x = 0.1, y = 1.55, paste("HL Test, df:", round(chisq.absrisk, 
                                                     3), ",", number.of.percentiles), cex = 1.3)
  text(x = 0.1, y = 1.3, paste("p-value:", noquote(ifelse(PVAL_absrisk < 
                                                            1e-100, "<1e-100", format.pval(PVAL_absrisk, digits = 20, 
                                                                                           eps = 1e-100, scientific = TRUE)))), cex = 1.3)
  text(x = 0.5, y = 1.8, "Relative Risk Calibration", font = 2, cex = 1.3)
  text(x = 0.5, y = 1.55, paste("Test, df:", round(chisq.logRR, 
                                                3), ",", number.of.percentiles - 1), cex = 1.3)
  text(x = 0.5, y = 1.3, paste("p-value:", noquote(ifelse(PVAL_logRR < 
                                                          1e-100, "<1e-100", format.pval(PVAL_logRR, digits = 20, 
                                                                                         eps = 1e-100, scientific = TRUE)))), cex = 1.3)
  text(x = 1.5, y = 1.8, "Model Discrimination", font = 2, cex = 1.3)
  text(x = 1.5, y = 1.55, paste("AUC est:", round(auc, 3)), cex = 1.3)
  text(x = 1.5, y = 1.3, paste("95% CI: (", round(lower.limit.auc, 
                                                  3), ",", round(upper.limit.auc, 3), ")"), cex = 1.3)
  
  text(x = 1.9, y = 1.925, "Model Discrimination", font = 2, cex = 1.3)
  text(x = 1.9, y = 1.675, "(Age Adjusted)", font = 2, cex = 1.3)
  text(x = 1.9, y = 1.425, paste("AUC est:", round(auc.lps, 3)), cex = 1.3)
  text(x = 1.9, y = 1.175, paste("95% CI: (", round(lower.limit.auc.lps, 
                                                  3), ",", round(upper.limit.auc.lps, 3), ")"), cex = 1.3)
  par(oldpar)
  NULL
}
