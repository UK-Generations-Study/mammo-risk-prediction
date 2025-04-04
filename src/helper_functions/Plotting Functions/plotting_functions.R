# library(ggplot2)
# library(dplyr)
# library(gt)
# library(formattable)

# Function to calculate number of bins
calculate_bins <- function(data, var, min_bins = 5, max_bins = 30) {
  x <- data[[var]]
  
  if (is.numeric(x)) {
    unique_vals <- length(unique(x))
    if (unique_vals <= max_bins) {
      return(unique_vals)
    } else {
      iqr <- IQR(x)
      n <- length(x)
      bin_width <- 2 * iqr / (n^(1/3))
      num_bins <- ceiling((max(x) - min(x)) / bin_width)
      return(min(num_bins, max_bins))
    }
  } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    x_numeric <- as.numeric(difftime(x, min(x), units = "days"))
    bin_width <- (max(x_numeric) - min(x_numeric)) / max_bins
    return(ceiling((max(x_numeric) - min(x_numeric)) / bin_width))
  } else {
    stop("Unsupported variable type for bin calculation.")
  }
}

# Output plot of
# Continuous distribution
# in the form of a histogram

plot_cts <- function(data, x_name, na_codes_x, integer) {
  
  data <- data[!data[[x_name]] %in% na_codes_x,]
  is_date <- inherits(data[[x_name]], "Date") || inherits(data[[x_name]], "POSIXt")
  
  if (!is_date) {
    summary_stats <- data %>%
      summarise(
        Min = min(!!sym(x_name), na.rm = TRUE),
        Med = median(!!sym(x_name), na.rm = TRUE),
        Max = max(!!sym(x_name), na.rm = TRUE)
      ) %>%
      mutate(Label = paste("Min:", round(Min, 2), "\nMed:", round(Med, 2), "\nMax:", round(Max, 2)))
  }
  
  num_bins <- calculate_bins(data, x_name)
  
  title <- paste("Distribution of", x_name)
  p <- ggplot(data, aes(x = !!sym(x_name)))
  if(!integer) {
    p <- p + geom_histogram(aes(y = after_stat(density)), bins = num_bins, fill = "forestgreen", color="black", boundary = 0)
  } else {
    p <- p + geom_histogram(aes(y = after_stat(density)), bins = num_bins, fill = "forestgreen", color="black", boundary = 0)
  }
  p <- p + theme_minimal() +
    labs(title = title, x = x_name, y = "Density") +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_blank(),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(colour = "black", linewidth = 1, fill = NA)
    )
  if (!is_date & nrow(data) > 0) p <- p +
    geom_label(data = summary_stats, aes(label = Label, x = Inf, y = Inf),
               hjust = 1, vjust = 1, fill = "white", color = "black", size = 3,
               position = position_nudge(y = -0.02))
  

  return(p)
  
}

# output table of 
# Categorical frequency distribution
# in the form of a table

plot_cat <- function(data, x_name, x_levels = NULL) {
  
  if (!is.null(x_levels)) {
    data[[x_name]] <- factor(data[[x_name]], levels = x_levels, labels = names(x_levels))
  }
  
  freq_table <- table(data[[x_name]])
  percentages <- round(100 * prop.table(freq_table), 2)
  
  # Sort the levels by frequency in descending order
  sorted_levels <- names(sort(freq_table, decreasing = TRUE))
  data[[x_name]] <- factor(data[[x_name]], levels = sorted_levels)
  
  sorted_freq_table <- table(data[[x_name]], useNA = "always")
  sorted_percentages <- round(100 * prop.table(sorted_freq_table), 2)
  
  formatted_table <- data.frame(
    Count = as.numeric(sorted_freq_table),
    Percentage = paste0(sorted_percentages, "%")
  )
  rownames(formatted_table) <- replace_na(as.character(names(sorted_freq_table)), "<NA>")
  
  gt_table <- formatted_table %>%
    gt(rownames_to_stub = TRUE) %>%
    tab_header(title = paste('Frequency Distribution of', x_name)) %>%
    tab_style(locations = cells_column_labels(), style = cell_text(weight = 'bold')) %>%
    tab_style(locations = cells_stub(rows = TRUE), style = cell_text(weight = 'bold')) %>%
    tab_options(table.align = "left")
  
  return(gt_table)
}

# Output plot of
# Continuous - Continuous relationships
# in the form of a heatmap

plot_cts_cts <- function(data, x_name, y_name, na_codes_x, na_codes_y) {
  number_of_bins <- 20
  data <- data[!data[[x_name]] %in% na_codes_x & !data[[y_name]] %in% na_codes_y,]
  title <- paste0(x_name, ' vs ', y_name)
  p <- ggplot(data, aes(x = !!sym(x_name), y = !!sym(y_name))) +
    geom_bin2d(color="white", bins=30) +
    scale_fill_gradient(name = "Count", low = "forestgreen", high = "darkorange") +
    labs(title = title) +

    theme_minimal() +
    theme(legend.position = "none",
          axis.text.x= element_text(angle = 45, hjust = 1),
          axis.ticks.x= element_blank(), 
          axis.text.y= element_text(), 
          axis.ticks.y= element_line(),
          plot.title = element_text(size = 16, hjust = 0.5),
          panel.border = element_rect(colour = "black", linewidth = 1, fill = NA))
  
  return(p)
}

# Output table of
# Categorical - Categorical relationships
# in the form of a cross-tabulation (with marginals and percentages)

plot_cat_cat <- function(data, x_name, y_name, x_levels = NULL, y_levels = NULL) {
  if(!is.null(x_levels)) data[[x_name]] <- factor(data[[x_name]], levels = x_levels, labels = names(x_levels))
  if(!is.null(y_levels)) data[[y_name]] <- factor(data[[y_name]], levels = y_levels, labels = names(y_levels))
  
  x_freq <- sort(table(data[[x_name]]), decreasing = TRUE)
  sorted_x_levels <- names(x_freq)
  
  data[[x_name]] <- factor(data[[x_name]], levels = sorted_x_levels)
  
  y_freq <- sort(table(data[[y_name]]), decreasing = TRUE)
  sorted_y_levels <- names(y_freq)
  
  data[[y_name]] <- factor(data[[y_name]], levels = sorted_y_levels)
  
  table_data <- table(data[[x_name]], data[[y_name]], useNA = "always")
  total_count <- sum(table_data)
  percentage_data <- 100 * prop.table(table_data)
  
  table_data <- rbind(table_data, 'Marginal' = colSums(table_data))
  table_data <- cbind(table_data, 'Marginal' = rowSums(table_data))
  
  percentage_data <- rbind(percentage_data, 'Marginal' = colSums(percentage_data))
  percentage_data <- cbind(percentage_data, 'Marginal' = rowSums(percentage_data))
  
  percentage_data <- round(percentage_data, 2)
  
  formatted_table <- matrix(nrow = nrow(table_data), ncol = ncol(table_data))
  for (i in 1:nrow(table_data)) {
    for (j in 1:ncol(table_data)) {
      formatted_table[i, j] <- paste0(table_data[i, j], " (", percentage_data[i, j], "%)")
    }
  }
  
  formatted_df <- as.data.frame(formatted_table)
  rownames(formatted_df) <- replace_na(as.character(rownames(table_data)), "<NA>")
  colnames(formatted_df) <- replace_na(as.character(colnames(table_data)), "<NA>")
  
  gt_table <- formatted_df %>%
    gt(rownames_to_stub = TRUE) %>%
    tab_header(title = md(paste('Distribution of', x_name, 'vs', y_name))) %>%
    tab_spanner(label = md(paste0("**", y_name, "**")), columns = everything()) %>%
    tab_stubhead(label = md(paste0("**", x_name, "**"))) %>%
    tab_style(locations = cells_column_labels(), style = cell_text(weight = 'bold')) %>%
    tab_style(locations = cells_stub(rows = TRUE), style = cell_text(weight = 'bold')) %>%
    tab_style(
      locations = cells_body(
        rows = nrow(formatted_df),
        columns = everything()
      ),
      style = cell_fill(color = "lightgrey")
    ) %>%
    tab_style(
      locations = cells_body(
        rows = everything(),
        columns = ncol(formatted_df)+1
      ),
      style = cell_fill(color = "lightgrey")
    ) %>%
    tab_options(
      row_group.as_column = TRUE,
      table.align = "left"
    )
  
  return(gt_table)
}

# Output plot of
# Categorical - Continuous relationships
# in the form of facet-wrapped histograms

plot_cat_cts <- function(data, x_name, y_name, x_levels = NULL, na_codes_y, title = NULL, xlab = NULL, ylab = "Density", integer) {
  data <- data %>% filter(!(data[[y_name]] %in% na_codes_y))
  if(!is.null(x_levels)) data[[x_name]] <- factor(data[[x_name]], levels = x_levels, labels = names(x_levels))
  
  if (is.null(title)) {
    title <- paste("Distribution of", y_name, "across levels of", x_name)
  }
  if (is.null(xlab)) {
    xlab <- y_name
  }
  
  summary_stats <- data %>%
    group_by(!!sym(x_name)) %>%
    summarise(
      Min = min(!!sym(y_name), na.rm = TRUE),
      Med = median(!!sym(y_name), na.rm = TRUE),
      Max = max(!!sym(y_name), na.rm = TRUE)
    ) %>%
    mutate(Label = paste("Min:", round(Min, 2), "\nMed:", round(Med, 2), "\nMax:", round(Max, 2)))
  
  num_bins <- calculate_bins(data, y_name)
  p <- ggplot(data, aes(x = !!sym(y_name)))
  if(!integer) {
    p <- p + geom_histogram(aes(y = after_stat(density)), bins = num_bins, fill = "forestgreen", color="black", boundary = 0)
  } else {
    p <- p + geom_histogram(aes(y = after_stat(density)), bins = num_bins, fill = "forestgreen", color="black", boundary = 0)
  }
  
  p <- p + facet_wrap(as.formula(paste("~", x_name)), scales = "free_y") +
    theme_minimal() +
    labs(title = title, x = xlab, y = ylab) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_blank(),
      plot.title = element_text(size = 16, hjust = 0.5),
      strip.text = element_text(size = 12),
      panel.border = element_rect(colour = "black", linewidth = 1, fill = NA)
    ) +
    geom_label(data = summary_stats, aes(label = Label, x = Inf, y = Inf),
               hjust = 1, vjust = 1, fill = "white", color = "black", size = 3,
               position = position_nudge(y = -0.02))
  
  return(p)
}

# plot_cts(data=data_rf, x_name='x_height_best', na_codes_x=c(888, 999, 989))
# 
# plot_cat(data=data_rf, x_name='x_ethnicity', x_levels=c('White'=1, 'Black'=2, 'Asian'=3, 'Mixed'=4, 'Missing'=9))
# 
# plot_cts_cts(data=data_rf, x_name='x_height_best', y_name='x_weight_entry', na_codes_x=c(888, 999, 989), na_codes_y=c(888, 999, 989))
# 
# plot_cat_cat(data=data_rf, x_name='x_bbd', 'x_ethnicity',
#              x_levels=c('No'=0, 'Yes'=1, 'Missing'=888),
#              y_levels=c('White'=1, 'Black'=2, 'Asian'=3, 'Mixed'=4, 'Missing'=9))
# 
# plot_cat_cts(data=data_rf, x_name='x_ethnicity', y_name='x_height_best', 
#              x_levels=c('White'=1, 'Black'=2, 'Asian'=3, 'Mixed'=4, 'Missing'=9),
#              na_codes_y=c(888, 999, 989))


