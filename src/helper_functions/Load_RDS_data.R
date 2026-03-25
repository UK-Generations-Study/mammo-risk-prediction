#' Load RDS Data
#' MEJones
#' April 2024
#'
#' This function loads and processes CSV data files along with
#' corresponding data dictionary files
#'
#' @param RDS_VERSION A character string specifying the folder
#' for the version of the frozen RDS data.
#' @param CSV_DATA_FILE_NAME A character string specifying the 
#' name of the RDS CSV data file.
#' @return A data frame containing the loaded RDS CSV data.
#' @export
#' @examples
#' riskfactors <- load_RDS_data("v20230927", "RDSRiskFactors.csv")

load_RDS_data <- function(RDS_VERSION, CSV_DATA_FILE_NAME) {
  # Read data dictionary from frozen RDS rollout
  ddfields <- read_data_dictionary(RDS_VERSION)
  # Read variable names from frozen CSV data file
  csv_names <- read_variable_names(RDS_VERSION, CSV_DATA_FILE_NAME)
  # Merge variable names from RDS CSV data file with data dictionary
  merged_data <- merge_with_data_dictionary(csv_names, ddfields)
  # Define variable types based on data dictionary
  merged_data <- define_variable_types(merged_data)
  # Read RDS CSV data file using defined variable types from data dictionary
  csv_data_temp <-
    read_csv_data(RDS_VERSION, CSV_DATA_FILE_NAME, merged_data)
  # Check for problems in loading CSV data file
  check_csv_data(RDS_VERSION, csv_data_temp, CSV_DATA_FILE_NAME)
  return(csv_data_temp)
}

# Function to read data dictionary
read_data_dictionary <- function(RDS_VERSION) {
  ddfields <-
    read_csv(
      paste0("//rds/data/dge/dudge/shared/GENERATIONS/CoreData/",
        RDS_VERSION, "/DDFields.csv"),
      na = c("NULL", ""),
      show_col_types = FALSE
    )
  ddfields <- ddfields %>% filter(!is.na(rds_variable))
  ddfields <- subset(
    ddfields,
    select = c(tableid, fieldid, fieldname, datatype, fielddesc)
  )
  # quick fix because data dictionary has same variable name for
  # different variables with different types
  # sort on tableID and then fieldID
  ddfields <- ddfields[order(ddfields$tableid, ddfields$fieldid), ]
  ddfields$lowerfieldname <- tolower(ddfields$fieldname)
  ddfields <- ddfields[!duplicated(ddfields$lowerfieldname), ]
  return(ddfields)
}

# Function to read variable names from CSV data file
read_variable_names <- function(RDS_VERSION, CSV_DATA_FILE_NAME) {
  csv_data_temp <-
    read_csv(
      paste0("//rds/data/dge/dudge/shared/GENERATIONS/CoreData/",
             RDS_VERSION, "/", CSV_DATA_FILE_NAME),
      na = c("NULL", ""),
      n_max = 1,
      show_col_types = FALSE
    )
  csv_names <- data.frame(names(csv_data_temp))
  csv_names <- csv_names %>% mutate(order = row_number())
  return(csv_names)
}

# Function to merge variable names with data dictionary
merge_with_data_dictionary <- function(csv_names, ddfields) {
  temp <- sqldf(
    "SELECT csv.\"names.csv_data_temp.\",
            csv.\"order\",
            dd.fieldname,
            dd.datatype,
            dd.fielddesc
    FROM csv_names as csv
    LEFT JOIN ddfields as dd on 
    csv.\"names.csv_data_temp.\" COLLATE NOCASE = dd.fieldname COLLATE NOCASE"
  )
  unique(temp$fieldname)
  return(temp)
}

# Function to define variable types
define_variable_types <- function(merged_data) {
  merged_data <- merged_data %>%
    mutate(
      variable_type = case_when(
        datatype %in% c("char", "nvarchar", "text", "varchar", "Yes/No") ~ "c",
        datatype %in% c("datetime", "Datetime") ~ "T",
        datatype %in% c("date") ~ "D",
        datatype %in% c("float", "num", "numeric", "real") ~ "d",
        datatype %in% c("int", "smallint") ~ "i",
        TRUE ~ "c"
      )
    )

  return(merged_data)
}


# Function to read CSV data file with defined variable types
read_csv_data <-
  function(RDS_VERSION,
           CSV_DATA_FILE_NAME,
           merged_data) {
    merged_data <- merged_data[order(merged_data$order), ]
    ctypes <- merged_data %>% select(variable_type) %>% dplyr::pull()
    cdesc <- merged_data %>% select(fielddesc) %>% dplyr::pull()
    csv_data_temp <-
      read_csv(
        paste0("//rds/data/dge/dudge/shared/GENERATIONS/CoreData/",
               RDS_VERSION, "/", CSV_DATA_FILE_NAME),
        col_types = paste(ctypes, collapse = ""),
        na = c("NULL", "NUL", ""),
        show_col_types = FALSE
      )
    # Set variable labels on the data frame
    for (i in seq_along(cdesc)) {
      var_name <- names(csv_data_temp)[i]  # Get the variable name
      label(csv_data_temp[[var_name]]) <- cdesc[i]  # Assign label to variable
    }
    return(csv_data_temp)
  }

# Function to check CSV data for problems
check_csv_data <-
  function(RDS_VERSION,
           csv_data_temp,
           CSV_DATA_FILE_NAME) {
    cat(
      paste0("Checking CSV data file: \n",
             "//rds/data/dge/dudge/shared/GENERATIONS/CoreData/",
             RDS_VERSION, "/", CSV_DATA_FILE_NAME))
    if (nrow(problems(csv_data_temp)) == 0) {
      cat(paste("\nSuccessful CSV import:", nrow(csv_data_temp), "rows\n"))
    } else {
      cat(paste("\nThere are problems with the CSV import\n"))
      print(problems(csv_data_temp))
    }
  }

# END OF load_RDS_data FUNCTION CODE