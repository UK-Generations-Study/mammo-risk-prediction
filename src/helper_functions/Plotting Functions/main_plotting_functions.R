######## PLOT GENERATION #########

# This .R contains two functions - one for plotting single variable info and one for plotting info between two variables

## PACKAGES ##
# library(patchwork)

# Function for plotting single variable

single_plot <- function(varname, data, datadict){
  
  # Get variable info
  var_info <- grab_var(varname, datadict)
  
  # Plot depends on the vartype
  
  # If categorical - just plot tabulation
  if(var_info[["vartype"]] == "cat"){
    print(plot_cat(data = data, x_name = var_info[["varname"]], x_levels = var_info[["codes"]]))
    
    
  } else if(var_info[["vartype"]] %in% c("dis", "cts")){ # If cts or discrete - plot non codes, then plot tabulation of codes
    
    # Plot histogram
    print(plot_cts(data = data, x_name = var_info[["varname"]], na_codes_x = var_info[["codes"]], integer= var_info[["datatype"]] == "integer"))
    
    # If codes - create new variable and plot the tabulation of that
    if(length(var_info[["codes"]]) > 0){
      
      data[[paste0(var_info[["varname"]], "_cat")]] <- "Valid"
      
      for(code in var_info[["codes"]]){
        data[[paste0(var_info[["varname"]], "_cat")]][data[[var_info[["varname"]]]] == code] <- names(var_info[["codes"]])[var_info[["codes"]] == code]
      }
      
      print(plot_cat(data = data, x_name = paste0(var_info[["varname"]], "_cat")))
      
    }
    
    # print(cont_plot)
    
  } else if(var_info[["vartype"]] == "string"){
    stop("ERROR: Cannot plot string variable types")
  } else {
    stop(paste0("ERROR: ", var_info[["vartype"]], "is not a recognised variable type"))
  }
  
  
}

# single_plot("parity", data, datadict)

double_plot <- function(varname1, varname2, data, datadict){
  
  # browser()
  
  # Grab variable info for both variables
  var_info_1 <- grab_var(varname1, datadict)
  var_info_2 <- grab_var(varname2, datadict)
  
  # Select plot based on variable types
  
  # If both categorical - just call cat_cat_function
  if(var_info_1[["vartype"]] == "cat" & var_info_2[["vartype"]] == "cat"){
    print(plot_cat_cat(data = data, x_name = var_info_1[["varname"]], y_name = var_info_2[["varname"]],
                 x_levels = var_info_1[["codes"]], y_levels = var_info_2[["codes"]]))
  } else if(var_info_1[["vartype"]] == "cat" & var_info_2[["vartype"]] %in% c("dis", "cts")){
    double_plot_cat_cts(data = data, cat_info = var_info_1, cts_info = var_info_2)
  } else if(var_info_1[["vartype"]] %in% c("dis", "cts") & var_info_2[["vartype"]] == "cat"){
    double_plot_cat_cts(data = data, cat_info = var_info_2, cts_info = var_info_1)

  } else if(var_info_1[["vartype"]] %in% c("dis", "cts") & var_info_2[["vartype"]] %in% c("dis", "cts")){
    double_plot_cts_cts(data = data, var_info_1 = var_info_1, var_info_2 = var_info_2)
  }
  
  
}

double_plot_cat_cts <- function(data, cat_info, cts_info){
  
  # Need to plot cat_cts then if the cts variable has a categorical component - then plot that too
  print(plot_cat_cts(data = data, x_name = cat_info[["varname"]], y_name = cts_info[["varname"]],
               x_levels = cat_info[["codes"]], na_codes_y = cts_info[["codes"]], integer= cts_info[["datatype"]] == "integer"))
  
  # If codes exist - make new variable with valid and NA codes
  if(length(cts_info[["codes"]]) > 0){
    
    data[[paste0(cts_info[["varname"]], "_cat")]] <- "Valid"
    
    for(code in cts_info[["codes"]]){
      data[[paste0(cts_info[["varname"]], "_cat")]][data[[cts_info[["varname"]]]] == code] <- names(cts_info[["codes"]])[cts_info[["codes"]] == code]
    }
    
    # Plot tabulation of cts NA codes and cat levels
    print(plot_cat_cat(data = data, x_name = paste0(cts_info[["varname"]], "_cat"), y_name = cat_info[["varname"]],
                 y_levels = cat_info[["codes"]]))
    
  }
}

double_plot_cts_cts <- function(data, var_info_1, var_info_2){
  
  # browser()
  
  # First plot the cts cts plot with the valid values
  print(plot_cts_cts(data = data, x_name = var_info_1[["varname"]], y_name = var_info_2[["varname"]],
                     na_codes_x = var_info_1[["codes"]], na_codes_y = var_info_2[["codes"]]))
  
  
  # If var 2 has codes, # Plot facetwrap of cts component of var 2 by var 1 NA status
  if(length(var_info_1[["codes"]]) > 0){

    data[[paste0(var_info_1[["varname"]], "_cat")]] <- "Valid"

    for(code in var_info_1[["codes"]]){
      data[[paste0(var_info_1[["varname"]], "_cat")]][data[[var_info_1[["varname"]]]] == code] <- names(var_info_1[["codes"]])[var_info_1[["codes"]] == code]
    }

    # Plot facetwrap of cts component of var 2 by var 1 NA status
    print(plot_cat_cts(data = data, x_name = paste0(var_info_1[["varname"]], "_cat"), y_name = var_info_2[["varname"]],
                       na_codes_y = var_info_2[["codes"]], integer = var_info_2[["datatype"]] == "integer"))
  }

  # If var 2 has codes, # Plot facetwrap of cts component of var 1 by var 2 NA status
  if(length(var_info_2[["codes"]]) > 0){

    data[[paste0(var_info_2[["varname"]], "_cat")]] <- "Valid"

    for(code in var_info_2[["codes"]]){
      data[[paste0(var_info_2[["varname"]], "_cat")]][data[[var_info_2[["varname"]]]] == code] <- names(var_info_2[["codes"]])[var_info_2[["codes"]] == code]
    }

    # Plot facetwrap of cts component of var 1 by var 2 NA status
    print(plot_cat_cts(data = data, x_name = paste0(var_info_2[["varname"]], "_cat"), y_name = var_info_1[["varname"]],
                       na_codes_y = var_info_1[["codes"]], integer = var_info_2[["datatype"]] == "integer"))
  }
  
  # If both variables have codes - plot tabulation of the NAs
  # NOTE: both of the above will have been done so don't need to recalculate the new variables
  if(length(var_info_1[["codes"]]) > 0 & length(var_info_2[["codes"]]) > 0){
    print(plot_cat_cat(data = data, x_name = paste0(var_info_1[["varname"]], "_cat"), y_name = paste0(var_info_2[["varname"]], "_cat")))
    
  }
  
}

# double_plot("parity", "age_birth_1", data, datadict)