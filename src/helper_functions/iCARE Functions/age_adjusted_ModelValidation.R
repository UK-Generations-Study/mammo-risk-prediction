# Same as ModelValidation from iCARE package, but the AUC is based on the absolute risk not the relative risk.

age_adjusted_ModelValidation <- function (study.data, total.followup.validation = FALSE, predicted.risk = NULL, 
                                          predicted.risk.interval = NULL, linear.predictor = NULL, 
                                          iCARE.model.object = list(model.formula = NULL, model.cov.info = NULL, 
                                                                    model.snp.info = NULL, model.log.RR = NULL, model.ref.dataset = NULL, 
                                                                    model.ref.dataset.weights = NULL, model.disease.incidence.rates = NULL, 
                                                                    model.competing.incidence.rates = NULL, model.bin.fh.name = NA, 
                                                                    apply.cov.profile = NULL, apply.snp.profile = NULL, 
                                                                    n.imp = 5, use.c.code = 1, return.lp = TRUE, return.refs.risk = TRUE), 
                                          number.of.percentiles = 10, reference.entry.age = NULL, 
                                          reference.exit.age = NULL, predicted.risk.ref = NULL, linear.predictor.ref = NULL, 
                                          linear.predictor.cutoffs = NULL, absrisk_decile = FALSE, dataset = "Example Dataset", 
                                          model.name = "Example Risk Prediction Model") 
{
  model.formula = iCARE.model.object$model.formula
  model.cov.info = iCARE.model.object$model.cov.info
  model.snp.info = iCARE.model.object$model.snp.info
  model.log.RR = iCARE.model.object$model.log.RR
  model.ref.dataset = iCARE.model.object$model.ref.dataset
  model.ref.dataset.weights = iCARE.model.object$model.ref.dataset.weights
  model.disease.incidence.rates = iCARE.model.object$model.disease.incidence.rates
  model.competing.incidence.rates = iCARE.model.object$model.competing.incidence.rates
  model.bin.fh.name = iCARE.model.object$model.bin.fh.name
  apply.cov.profile = iCARE.model.object$apply.cov.profile
  apply.snp.profile = iCARE.model.object$apply.snp.profile
  n.imp = iCARE.model.object$n.imp
  use.c.code = iCARE.model.object$use.c.code
  return.lp = iCARE.model.object$return.lp
  return.refs.risk = iCARE.model.object$return.refs.risk
  mf = paste(model.formula)
  if (total.followup.validation) {
    timeframe = "Observed Followup"
  }
  else timeframe = paste(predicted.risk.interval, "years")
  observed.outcome = study.data$observed.outcome
  study.entry.age = study.data$study.entry.age
  study.exit.age = study.data$study.exit.age
  time.of.onset = study.data$time.of.onset
  sampling.weights = study.data$sampling.weights
  if (any(study.entry.age >= study.exit.age)) {
    print("Error: entry age should be lower than exit age")
    stop()
  }
  observed.followup = study.exit.age - study.entry.age
  observed.outcome[observed.outcome == 1 & time.of.onset > 
                     observed.followup] = 0
  time.of.onset[observed.outcome == 1 & time.of.onset > observed.followup] = Inf
  followup = observed.followup
  if (total.followup.validation) {
    predicted.risk.interval = observed.followup
  }
  if (length(predicted.risk.interval) == 1) {
    predicted.risk.interval = rep(predicted.risk.interval, 
                                  length(observed.outcome))
  }
  followup[(time.of.onset <= predicted.risk.interval & predicted.risk.interval <= 
              observed.followup)] = predicted.risk.interval[(time.of.onset <= 
                                                               predicted.risk.interval & predicted.risk.interval <= 
                                                               observed.followup)]
  observed.outcome[predicted.risk.interval < time.of.onset & 
                     time.of.onset <= observed.followup] = 0
  followup[predicted.risk.interval < time.of.onset & time.of.onset <= 
             observed.followup] = predicted.risk.interval[predicted.risk.interval < 
                                                            time.of.onset & time.of.onset <= observed.followup]
  followup[predicted.risk.interval <= observed.followup & 
             observed.followup < time.of.onset] = predicted.risk.interval[predicted.risk.interval <= 
                                                                            observed.followup & observed.followup < time.of.onset]
  if (is.null(predicted.risk) | is.null(linear.predictor)) {
    pred.risk = computeAbsoluteRisk(model.formula = model.formula, 
                                    model.cov.info = model.cov.info, model.snp.info = model.snp.info, 
                                    model.log.RR = model.log.RR, model.ref.dataset = model.ref.dataset, 
                                    model.ref.dataset.weights = NULL, model.disease.incidence.rates = model.disease.incidence.rates, 
                                    model.competing.incidence.rates = model.competing.incidence.rates, 
                                    model.bin.fh.name = model.bin.fh.name, apply.age.start = study.entry.age, 
                                    apply.age.interval.length = followup, apply.cov.profile = apply.cov.profile, 
                                    apply.snp.profile = apply.snp.profile, use.c.code = use.c.code, 
                                    return.lp = return.lp, return.refs.risk = return.refs.risk)
    predicted.risk = as.numeric(pred.risk$risk)
    linear.predictor = as.numeric(pred.risk$lps)
  }
  if ((is.null(predicted.risk.ref) | is.null(linear.predictor.ref)) & 
      (!is.null(reference.entry.age)) & (!is.null(reference.exit.age))) {
    reference.followup = reference.exit.age - reference.entry.age
    predicted.risk.ref = computeAbsoluteRisk(model.formula = model.formula, 
                                             model.cov.info = model.cov.info, model.snp.info = model.snp.info, 
                                             model.log.RR = model.log.RR, model.ref.dataset = model.ref.dataset, 
                                             model.ref.dataset.weights = NULL, model.disease.incidence.rates = model.disease.incidence.rates, 
                                             model.competing.incidence.rates = model.competing.incidence.rates, 
                                             model.bin.fh.name = model.bin.fh.name, apply.age.start = reference.entry.age, 
                                             apply.age.interval.length = reference.followup, 
                                             apply.cov.profile = model.ref.dataset, apply.snp.profile = NULL, 
                                             use.c.code = use.c.code, return.lp = return.lp, 
                                             return.refs.risk = return.refs.risk)
    linear.predictor.ref = as.numeric(predicted.risk.ref$lps)
    predicted.risk.ref = as.numeric(predicted.risk.ref$refs.risk)
  }
  linear.predictor.cases = linear.predictor[observed.outcome == 
                                              1]
  linear.predictor.controls = linear.predictor[observed.outcome == 
                                                 0]
  abs.risk.cases = predicted.risk[observed.outcome == 1]
  abs.risk.controls = predicted.risk[observed.outcome == 0]
  indicator = vapply(linear.predictor.cases, function(x) x > 
                       linear.predictor.controls, logical(length(linear.predictor.controls)))
  indicator.abs = vapply(abs.risk.cases, function(x) x > 
                           abs.risk.controls, logical(length(abs.risk.controls)))
  indicator.lps = vapply(linear.predictor.cases, function(x) x > #####
                            linear.predictor.controls, logical(length(linear.predictor.controls))) #####
  if (!is.null(sampling.weights)) {
    
    freq = 1/sampling.weights
    ages = (min(study.entry.age) + 1):(max(study.exit.age) - 
                                         1)
    len_ages = length(ages)
    age.of.onset = study.entry.age + time.of.onset
    study_incidence = rep(0, len_ages)
    for (i in 1:len_ages) {
      a = sum((study.entry.age <= ages[i] - 1 & age.of.onset >= 
                 ages[i] & age.of.onset < ages[i] + 1 & study.exit.age >= 
                 ages[i]) * freq)
      b = sum((study.entry.age <= ages[i] - 1 & study.exit.age >= 
                 ages[i] & age.of.onset >= ages[i]) * freq)
      study_incidence[i] = a/b
    }
    study_incidence = cbind(ages, study_incidence)
    sampling.weights.cases = sampling.weights[observed.outcome == 
                                                1]
    sampling.weights.controls = sampling.weights[observed.outcome == 
                                                   0]
    freq.cases = freq[observed.outcome == 1]
    freq.controls = freq[observed.outcome == 0]
    weight.mat = matrix(kronecker(freq.controls, freq.cases), 
                        nrow = length(freq.controls), byrow = TRUE)
    auc = sum(indicator.abs * weight.mat)/sum(weight.mat)
    auc.lps = sum(indicator.lps * weight.mat)/sum(weight.mat) #####
    mean_S0_indicator = apply(indicator.abs, 2, weighted.mean, 
                              w = freq.controls)
    mean_S0_indicator.lps = apply(indicator.lps, 2, weighted.mean, ######
                              w = freq.controls) #####
    mean_S1_indicator = apply(indicator.abs, 1, weighted.mean, 
                              w = freq.cases)
    mean_S1_indicator.lps = apply(indicator.lps, 1, weighted.mean, #####
                              w = freq.cases) #####
    term1 = wtd.var(mean_S0_indicator, weights = freq.cases) + 
      weighted.mean((mean_S0_indicator - auc)^2 * (1 - 
                                                     sampling.weights.cases)/sampling.weights.cases,
                    w = freq.cases)
    term1.lps = wtd.var(mean_S0_indicator.lps, weights = freq.cases) + #####
      weighted.mean((mean_S0_indicator.lps - auc.lps)^2 * (1 - #####
                                                     sampling.weights.cases)/sampling.weights.cases, #####
                    w = freq.cases)
    term2 = wtd.var(mean_S1_indicator, weights = freq.controls) + 
      weighted.mean((mean_S1_indicator - auc)^2 * (1 - 
                                                     sampling.weights.controls)/sampling.weights.controls, 
                    w = freq.controls)
    term2.lps = wtd.var(mean_S1_indicator.lps, weights = freq.controls) + #####
      weighted.mean((mean_S1_indicator.lps - auc.lps)^2 * (1 - #####
                                                     sampling.weights.controls)/sampling.weights.controls, #####
                    w = freq.controls)
    var_auc = term1/sum(freq.cases) + term2/sum(freq.controls)
    var_auc.lps = term1.lps/sum(freq.cases) + term2.lps/sum(freq.controls)
    p_E = (sum(predicted.risk * freq))/(sum(freq))
    p_O = (sum(observed.outcome * freq))/(sum(freq))
    var_obsrisk = (p_O * (1 - p_O) + sum((observed.outcome - 
                                            p_O)^2 * (1 - sampling.weights)/sampling.weights^2)/sum(freq))/sum(freq)
    var_log_exp_by_obs = var_obsrisk/p_O^2
    exp_by_obs = p_E/p_O
    CI_exp_by_obs = exp(c(log(exp_by_obs) - 1.96 * sqrt(var_log_exp_by_obs), 
                          log(exp_by_obs) + 1.96 * sqrt(var_log_exp_by_obs)))
    if (!is.null(linear.predictor.cutoffs)) {
      linear.predictor.cutoffs = c(min(linear.predictor), 
                                   linear.predictor.cutoffs, max(linear.predictor))
      linear.predictor.cat = cut(linear.predictor, breaks = linear.predictor.cutoffs, 
                                 include.lowest = TRUE)
    }
    else {
      if(!absrisk_decile){ ###
        linear.predictor.cat = weighted.quantcut(linear.predictor, ###
                                                 weights = freq, q = number.of.percentiles) ###
      } else { ###
        linear.predictor.cat = weighted.quantcut(predicted.risk, ###
                                                 weights = freq, q = number.of.percentiles) ###
      }
    }
    wtd.samp.size.cat = aggregate(freq ~ linear.predictor.cat, 
                                  FUN = sum)$freq
    obs.prob.wt = observed.outcome * freq
    obs.prob.wt.cat = aggregate(obs.prob.wt ~ linear.predictor.cat, 
                                FUN = sum)
    wt.cat = aggregate(freq ~ linear.predictor.cat, FUN = sum)
    observed.prob.cat = obs.prob.wt.cat$obs.prob.wt/wt.cat$freq
    pred.prob.wt = predicted.risk * freq
    pred.prob.wt.cat = aggregate(pred.prob.wt ~ linear.predictor.cat, 
                                 FUN = sum)
    predicted.prob.cat = pred.prob.wt.cat$pred.prob.wt/wt.cat$freq
    observed.risk.cat = linear.predictor.cat
    
    levels(observed.risk.cat) = observed.prob.cat
    observed.risk.cat = as.numeric(as.character(observed.risk.cat))
    var.absrisk.corr = (observed.outcome - observed.risk.cat)^2 * 
      (1 - sampling.weights)/(sampling.weights)^2
    var.absrisk.corr.cat = (aggregate(var.absrisk.corr ~ 
                                        linear.predictor.cat, FUN = sum)$var.absrisk.corr)/wt.cat$freq
    variance.absrisk.cat = (observed.prob.cat * (1 - observed.prob.cat) + 
                              var.absrisk.corr.cat)/wt.cat$freq
    sd.absrisk.cat = sqrt(variance.absrisk.cat)
    chisq.absrisk = sum(((observed.prob.cat - predicted.prob.cat)^2)/variance.absrisk.cat)
    mu_bar = mean(observed.prob.cat)
    observed.RR.cat = observed.prob.cat/mu_bar
    predicted.RR.cat = predicted.prob.cat/mean(predicted.prob.cat)
    variance.mat.absrisk = diag(variance.absrisk.cat)
    derivative_offdiagonal = -1/(number.of.percentiles * 
                                   mu_bar)
    derivative_diagonal = diag(1/observed.prob.cat + derivative_offdiagonal)
    derivative_diagonal[lower.tri(derivative_diagonal)] = derivative_offdiagonal
    derivative_diagonal[upper.tri(derivative_diagonal)] = derivative_offdiagonal
    derivative.mat = derivative_diagonal[-number.of.percentiles, 
    ]
    varcov.logRR.cat = derivative_diagonal %*% variance.mat.absrisk %*% 
      derivative_diagonal
    sd.logRR.cat = sqrt(diag(varcov.logRR.cat))
    sigmainv_logRR = solve(derivative.mat %*% variance.mat.absrisk %*% 
                             t(derivative.mat))
    diff.logRR = (log(observed.RR.cat) - log(predicted.RR.cat))[-number.of.percentiles]
    chisq.logRR = as.numeric(diff.logRR %*% sigmainv_logRR %*% 
                               t(t(diff.logRR)))
    PVAL_absrisk = 1 - pchisq(chisq.absrisk, number.of.percentiles)
    PVAL_logRR = 1 - pchisq(chisq.logRR, number.of.percentiles - 
                              1)
    upper.limit.absrisk.cat = observed.prob.cat + 1.96 * 
      sd.absrisk.cat
    lower.limit.absrisk.cat = observed.prob.cat - 1.96 * 
      sd.absrisk.cat
    upper.limit.RR.cat = exp(log(observed.RR.cat) + 1.96 * 
                               sd.logRR.cat)
    lower.limit.RR.cat = exp(log(observed.RR.cat) - 1.96 * 
                               sd.logRR.cat)
    upper.limit.auc = auc + 1.96 * sqrt(var_auc)
    lower.limit.auc = auc - 1.96 * sqrt(var_auc)
    upper.limit.auc.lps = auc.lps + 1.96 * sqrt(var_auc.lps) #####
    lower.limit.auc.lps = auc.lps - 1.96 * sqrt(var_auc.lps) #####
  }
  else {
    print("No sampling weights provided: assuming each subject has sampling weight 1")
    ages = (min(study.entry.age) + 1):(max(study.exit.age) - 
                                         1)
    len_ages = length(ages)
    age.of.onset = study.entry.age + time.of.onset
    study_incidence = rep(0, len_ages)
    for (i in 1:len_ages) {
      a = sum(study.entry.age <= ages[i] - 1 & age.of.onset >= 
                ages[i] & age.of.onset < ages[i] + 1 & study.exit.age >= 
                ages[i])
      b = sum(study.entry.age <= ages[i] - 1 & study.exit.age >= 
                ages[i] & age.of.onset >= ages[i])
      study_incidence[i] = a/b
    }
    study_incidence = cbind(ages, study_incidence)
    auc = mean(indicator.abs)
    auc.lps = mean(indicator.lps) #####
    mean_S0_indicator = apply(indicator.abs, 2, mean)
    mean_S0_indicator.lps = apply(indicator.lps, 2, mean) #####
    mean_S1_indicator = apply(indicator.abs, 1, mean)
    mean_S1_indicator.lps = apply(indicator.lps, 1, mean) #####
    var_auc = var(mean_S0_indicator)/length(mean_S0_indicator) + 
      var(mean_S1_indicator)/length(mean_S1_indicator)
    var_auc.lps = var(mean_S0_indicator.lps)/length(mean_S0_indicator.lps) + #####
      var(mean_S1_indicator.lps)/length(mean_S1_indicator.lps) #####
    p_E = mean(predicted.risk)
    p_O = mean(observed.outcome)
    var_obsrisk = (p_O * (1 - p_O))/length(predicted.risk)
    var_log_exp_by_obs = var_obsrisk/p_O^2
    exp_by_obs = p_E/p_O
    CI_exp_by_obs = exp(c(log(exp_by_obs) - 1.96 * sqrt(var_log_exp_by_obs), 
                          log(exp_by_obs) + 1.96 * sqrt(var_log_exp_by_obs)))
    if (!is.null(linear.predictor.cutoffs)) {
      linear.predictor.cutoffs = c(min(linear.predictor), 
                                   linear.predictor.cutoffs, max(linear.predictor))
      linear.predictor.cat = cut(linear.predictor, breaks = linear.predictor.cutoffs, 
                                 include.lowest = TRUE)
    }
    else {
      if(!absrisk_decile) { ###
        linear.predictor.cat = quantcut(linear.predictor,  ###
                                        q = number.of.percentiles) ###
      } else { ###
        linear.predictor.cat = quantcut(predicted.risk,  ###
                                        q = number.of.percentiles) ###
      } ###
    }
    samp.size.cat = as.numeric(table(linear.predictor.cat))
    observed.prob.cat = aggregate(observed.outcome ~ linear.predictor.cat, 
                                  FUN = mean)$observed.outcome
    predicted.prob.cat = aggregate(predicted.risk ~ linear.predictor.cat, 
                                   FUN = mean)$predicted.risk
    variance.absrisk.cat = (observed.prob.cat * (1 - observed.prob.cat))/samp.size.cat
    sd.absrisk.cat = sqrt(variance.absrisk.cat)
    chisq.absrisk = sum(((observed.prob.cat - predicted.prob.cat)^2)/variance.absrisk.cat)
    mu_bar = mean(observed.prob.cat)
    observed.RR.cat = observed.prob.cat/mu_bar
    predicted.RR.cat = predicted.prob.cat/mean(predicted.prob.cat)
    variance.mat.absrisk = diag(variance.absrisk.cat)
    derivative_offdiagonal = -1/(number.of.percentiles * 
                                   mu_bar)
    derivative_diagonal = diag(1/observed.prob.cat + derivative_offdiagonal)
    derivative_diagonal[lower.tri(derivative_diagonal)] = derivative_offdiagonal
    derivative_diagonal[upper.tri(derivative_diagonal)] = derivative_offdiagonal
    derivative.mat = derivative_diagonal[-number.of.percentiles, 
    ]
    varcov.logRR.cat = derivative_diagonal %*% variance.mat.absrisk %*% 
      derivative_diagonal
    sd.logRR.cat = sqrt(diag(varcov.logRR.cat))
    sigmainv_logRR = solve(derivative.mat %*% variance.mat.absrisk %*% 
                             t(derivative.mat))
    diff.logRR = (log(observed.RR.cat) - log(predicted.RR.cat))[-number.of.percentiles]
    chisq.logRR = as.numeric(diff.logRR %*% sigmainv_logRR %*% 
                               t(t(diff.logRR)))
    PVAL_absrisk = 1 - pchisq(chisq.absrisk, number.of.percentiles)
    PVAL_logRR = 1 - pchisq(chisq.logRR, number.of.percentiles - 
                              1)
    upper.limit.absrisk.cat = observed.prob.cat + 1.96 * 
      sd.absrisk.cat
    lower.limit.absrisk.cat = observed.prob.cat - 1.96 * 
      sd.absrisk.cat
    upper.limit.RR.cat = exp(log(observed.RR.cat) + 1.96 * 
                               sd.logRR.cat)
    lower.limit.RR.cat = exp(log(observed.RR.cat) - 1.96 * 
                               sd.logRR.cat)
    upper.limit.auc = auc + 1.96 * sqrt(var_auc)
    lower.limit.auc = auc - 1.96 * sqrt(var_auc)
    upper.limit.auc.lps = auc.lps + 1.96 * sqrt(var_auc.lps) #####
    lower.limit.auc.lps = auc.lps - 1.96 * sqrt(var_auc.lps) #####
  }
  DNAME <- paste(deparse(substitute(observed.frequency)), 
                 deparse(substitute(expected.frequency)), sep = ", ")
  METHOD = "Hosmer and Lemeshow goodness of fit (GOF) test for Absolute Risk"
  names(chisq.absrisk) = "Chisquare"
  names(number.of.percentiles) = "df"
  h1 = structure(list(statistic = chisq.absrisk, parameter = number.of.percentiles, 
                      p.value = PVAL_absrisk, method = METHOD, data.name = DNAME), 
                 class = "htest")
  DNAME <- paste(deparse(substitute(observed.frequency)), 
                 deparse(substitute(expected.frequency)), sep = ", ")
  METHOD = "Goodness of fit (GOF) test for Relative Risk"
  names(chisq.logRR) = "Chisquare"
  names(number.of.percentiles) = "df"
  h2 = structure(list(statistic = chisq.logRR, parameter = number.of.percentiles - 
                        1, p.value = PVAL_logRR, method = METHOD, data.name = DNAME), 
                 class = "htest")
  results.cat = data.frame(cbind(levels(linear.predictor.cat), 
                                 observed.prob.cat, predicted.prob.cat, lower.limit.absrisk.cat, 
                                 upper.limit.absrisk.cat, observed.RR.cat, predicted.RR.cat, 
                                 lower.limit.RR.cat, upper.limit.RR.cat))
  names(results.cat) = c("Categories", "Observed_Absolute_Risk", 
                         "Predicted_Absolute_Risk", "CI_Absolute_Risk_Lower", 
                         "CI_Absolute_Risk_Upper", "Observed_Relative_Risk", 
                         "Predicted_Relative_Risk", "CI_Relative_Risk_Lower", 
                         "CI_Relative_Risk_Upper")
  
  ### CREATING CALIBRATION SLOPE ###
  
  
  cal.slope <- lm(observed.prob.cat ~ predicted.prob.cat)
  
  
  ### END OF CALIBRATION SLOPE CREATION ###
  
  
  ### TEST - PRINTING E/O FOR FINAL DECILE ###
  
  cat("\n\nE/O for final decile: ", predicted.prob.cat[length(predicted.prob.cat)]/observed.prob.cat[length(predicted.prob.cat)], "\n\n")
  
  
  
  ret <- list(Subject_Specific_Observed_Outcome = observed.outcome, 
              Risk_Prediction_Interval = timeframe, Adjusted_Followup = followup, 
              Subject_Specific_Predicted_Absolute_Risk = predicted.risk, 
              Reference_Absolute_Risk = predicted.risk.ref, Subject_Specific_Risk_Score = linear.predictor, 
              Reference_Risk_Score = linear.predictor.ref, Population_Incidence_Rate = model.disease.incidence.rates, 
              Study_Incidence_Rate = study_incidence, Category_Results = results.cat, 
              Category_Specific_Observed_Absolute_Risk = observed.prob.cat, 
              Category_Specific_Predicted_Absolute_Risk = predicted.prob.cat, 
              Category_Specific_Observed_Relative_Risk = observed.RR.cat, 
              Category_Specific_Predicted_Relative_Risk = predicted.RR.cat, 
              Variance_Matrix_Absolute_Risk = variance.mat.absrisk, 
              Variance_Matrix_LogRelative_Risk = varcov.logRR.cat, 
              Hosmer_Lemeshow_Results = h1, HL_pvalue = PVAL_absrisk, 
              RR_test_result = h2, RR_test_pvalue = PVAL_logRR, AUC = auc, AUC.lps = auc.lps, ##### 
              Variance_AUC = var_auc, CI_AUC = c(lower.limit.auc, 
                                                 upper.limit.auc), Overall_Expected_to_Observed_Ratio = exp_by_obs, 
              Variance_AUC.lps = var_auc.lps, CI_AUC.lps = c(lower.limit.auc.lps, #####
                                                 upper.limit.auc.lps), Overall_Expected_to_Observed_Ratio = exp_by_obs,######
              CI_Overall_Expected_to_Observed_Ratio = CI_exp_by_obs, 
              input.args = list(model.formula = model.formula, study.data = study.data, 
                                dataset = dataset, model.name = model.name),
              cal.slope = cal.slope)
  class(ret) <- "icareValid"
  ret
}
