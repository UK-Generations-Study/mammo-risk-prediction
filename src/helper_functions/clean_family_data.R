## CLEAN FAMILY DATA FUNCTION ##

# This function is designed to clean pedigree level data and input names for family members relative to their relation to a target.
# Inputs:
#   data - pedigree level data to be fed in. Should be structured the same as GS Pedigree data.
#   option - option to clean certain standard.
#       Options: "IBIS", "First Degree", "Second Degree"
#   remove - option to remove participants not in list of needed relatives

clean_family_data <- function(data, option, remove = T){
  
  # Get list of relatives needed for option
  option_relatives <- case_when(
    option == "IBIS" ~ list(c("Mother", "Father", "Sister", "Brother", "Grandparent", "Aunt", "Uncle", "Cousin (F)", "Daughter", "Half-Sister")),
    option == "First Degree" ~ list(c("Mother", "Father", "Sister", "Brother", "Son", "Daughter")),
    option == "Second Degree" ~ list(c("Mother", "Father", "Sister", "Brother", "Son", "Daughter", "Aunt", "Uncle", "Niece", "Nephew", "Half-Sister", "Half-Brother", "Grandparent")),
    option == "All" ~ list(c("Mother", "Father", "Sister", "Brother", "Son", "Daughter", "Aunt", "Uncle", "Niece", "Nephew", "Half-Sister", "Half-Brother", "Grandparent", "Cousin (F)", "Cousin (M)", "Granddaughter", "Grandson"))
  )
  option_relatives <- unlist(option_relatives)
  
  
  # Initialise empty name column
  data$Name_2 <- "REMOVE"
  
  # Get target
  targetid <- data$IndivID[data$Target == 1]
  data$Name_2[data$Target==1] <- "Target"
  
  # Get parents
  # Get father
  if("Father" %in% option_relatives){
    fatherid <- data$FathID[data$Name_2 == "Target"] # Get father id as fatherid of target
    data$Name_2[data$IndivID == fatherid] <- "Father" # Label name to father
    fatherid <- if_else(fatherid == 0, 999, fatherid) # Remove case where father id is 0 and matches with another father id etc
  }
  
  # Get mother
  if("Mother" %in% option_relatives){
    motherid <- data$MothID[data$Name_2 == "Target"]
    data$Name_2[data$IndivID == motherid] <- "Mother"
    motherid <- if_else(motherid == 0, 999, motherid)
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get sisters
  if("Sister" %in% option_relatives){
    sistersid <- data$IndivID[data$FathID == fatherid & data$MothID == motherid & data$Sex == "F"]
    sistersid <- sistersid[sistersid != targetid] # Target is also child of the parents but not a sister
    data$Name_2[data$IndivID %in% sistersid] <- paste0(rep("Sister ", length(sistersid)), 1:length(sistersid)) # Need to distinguish between sisters for nieces
  }
  
  # Get brothers
  if("Brother" %in% option_relatives){
    brothersid <- data$IndivID[data$FathID == fatherid & data$MothID == motherid & data$Sex == "M"]
    brothersid <- brothersid[brothersid != targetid]
    data$Name_2[data$IndivID %in% brothersid] <- "Brother"
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get daughters
  if("Daughter" %in% option_relatives){
    daughtersid <- data$IndivID[data$MothID == targetid & data$Sex == "F"]
    data$Name_2[data$IndivID %in% daughtersid] <- "Daughter"
  }
  
  # Get sons
  if("Son" %in% option_relatives){
    sonsid <- data$IndivID[data$MothID == targetid & data$Sex == "M"]
    data$Name_2[data$IndivID %in% sonsid] <- "Son"
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get grandparents
  if("Grandparent" %in% option_relatives){
    fatherfatherid <- data$FathID[data$Name_2 == "Father"]
    data$Name_2[data$IndivID == fatherfatherid] <- "Paternal Grandfather"
    fatherfatherid <- if_else(fatherfatherid == 0, 999, fatherfatherid)
    
    fathermotherid <- data$MothID[data$Name_2 == "Father"]
    data$Name_2[data$IndivID == fathermotherid] <- "Paternal Grandmother"
    fathermotherid <- if_else(fathermotherid == 0, 999, fathermotherid)
    
    motherfatherid <- data$FathID[data$Name_2 == "Mother"]
    data$Name_2[data$IndivID == motherfatherid] <- "Maternal Grandfather"
    motherfatherid <- if_else(motherfatherid == 0, 999, motherfatherid)
    
    mothermotherid <- data$MothID[data$Name_2 == "Mother"]
    data$Name_2[data$IndivID == mothermotherid] <- "Maternal Grandmother"
    mothermotherid <- if_else(mothermotherid == 0, 999, mothermotherid)
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get aunts
  if("Aunt" %in% option_relatives){
    mauntsid <- data$IndivID[data$FathID == motherfatherid & data$MothID == mothermotherid & data$Sex == "F"] # Are both necessary - what about half-aunts?
    mauntsid <- mauntsid[mauntsid != motherid] # Mother needs to be excluded from maternal aunts
    data$Name_2[data$IndivID %in% mauntsid] <- paste0(rep("Maternal Aunt ", length(mauntsid)), 1:length(mauntsid)) # Need to distinguish between aunts for cousins
    
    pauntsid <- data$IndivID[data$FathID == fatherfatherid & data$MothID == fathermotherid & data$Sex == "F"] # Are both necessary - what about half-aunts?
    data$Name_2[data$IndivID %in% pauntsid] <- paste0(rep("Paternal Aunt ", length(pauntsid)), 1:length(pauntsid)) # Need to distinguish between aunts for cousins
  }
  
  # Get uncles
  if("Uncle" %in% option_relatives){
    munclesid <- data$IndivID[data$FathID == motherfatherid & data$MothID == mothermotherid & data$Sex == "M"] # Are both necessary - what about half-uncles?
    data$Name_2[data$IndivID %in% munclesid] <- paste0(rep("Maternal Uncle ", length(munclesid)), 1:length(munclesid)) # Need to distinguish between uncles for cousins
    
    punclesid <- data$IndivID[data$FathID == fatherfatherid & data$MothID == fathermotherid & data$Sex == "M"] # Are both necessary - what about half-uncles?
    punclesid <- punclesid[punclesid != fatherid] # Father needs to be excluded from paternal uncles
    data$Name_2[data$IndivID %in% punclesid] <- paste0(rep("Paternal Uncle ", length(punclesid)), 1:length(punclesid)) # Need to distinguish between uncles for cousins
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get Nieces
  if("Niece" %in% option_relatives){
    
    # Get Nieces - Sisters
    for(i in seq_along(sistersid)){ # Order is preserved from original order of sistersid - so SNiece 1 is daughter of Sister 1.
      
      sniecesid <- data$IndivID[data$MothID == sistersid[i] & data$Sex == "F"]
      data$Name_2[data$IndivID %in% sniecesid] <- paste0("SNiece ", i) # NOTE: The number refers to the number of their mother not them. i.e can have 2 SNiece 1's
      
    }
    
    # Get Nieces - Brothers
    # Code is not concerned with the father - they're all in one group
    bniecesid <- data$IndivID[data$FathID %in% brothersid & data$Sex == "F"]
    data$Name_2[data$IndivID %in% bniecesid] <- "BNiece"
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get Nephews
  if("Nephew" %in% option_relatives){
    
    # Get Nephews - Sisters
    for(i in seq_along(sistersid)){ # Order is preserved from original order of sistersid - so SNephew 1 is son of Sister 1.
      
      snephewsid <- data$IndivID[data$MothID == sistersid[i] & data$Sex == "M"]
      data$Name_2[data$IndivID %in% snephewsid] <- paste0("SNephew ", i) # NOTE: The number refers to the number of their mother not them. i.e can have 2 SNephew 1's
      
    }
    
    # Get Nephews - Brothers
    # Code is not concerned with the father - they're all in one group
    bnephewsid <- data$IndivID[data$FathID %in% brothersid & data$Sex == "M"]
    data$Name_2[data$IndivID %in% bnephewsid] <- "BNephew"
    
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get Cousins (Female)
  if("Cousin (F)" %in% option_relatives){  
    # Similar structure to the Sisters Nieces but need to go through Paternal Aunt, Maternal Uncle etc.
    for(i in seq_along(mauntsid)){
      
      cousinsid <- data$IndivID[data$MothID == mauntsid[i] & data$Sex == "F"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("MAunt Daughter ", i)
      
    }
    
    for(i in seq_along(pauntsid)){
      
      cousinsid <- data$IndivID[data$MothID == pauntsid[i] & data$Sex == "F"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("PAunt Daughter ", i)
      
    }
    
    for(i in seq_along(munclesid)){
      
      cousinsid <- data$IndivID[data$FathID == munclesid[i] & data$Sex == "F"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("MUncle Daughter ", i)
      
    }
    
    for(i in seq_along(punclesid)){
      
      cousinsid <- data$IndivID[data$FathID == punclesid[i] & data$Sex == "F"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("PUncle Daughter ", i)
      
    }
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get Cousins (Male)
  if("Cousin (M)" %in% option_relatives){  
    # Similar structure to the Sisters Nieces but need to go through Paternal Aunt, Maternal Uncle etc.
    for(i in seq_along(mauntsid)){
      
      cousinsid <- data$IndivID[data$MothID == mauntsid[i] & data$Sex == "M"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("MAunt Son ", i)
      
    }
    
    for(i in seq_along(pauntsid)){
      
      cousinsid <- data$IndivID[data$MothID == pauntsid[i] & data$Sex == "M"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("PAunt Son ", i)
      
    }
    
    for(i in seq_along(munclesid)){
      
      cousinsid <- data$IndivID[data$FathID == munclesid[i] & data$Sex == "M"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("MUncle Son ", i)
      
    }
    
    for(i in seq_along(punclesid)){
      
      cousinsid <- data$IndivID[data$FathID == punclesid[i] & data$Sex == "M"]
      data$Name_2[data$IndivID %in% cousinsid] <- paste0("PUncle Son ", i)
      
    }
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get Half-Sisters
  if("Half-Sister" %in% option_relatives){
    phsistersid <- data$IndivID[data$FathID == fatherid & data$MothID != motherid & data$Sex == "F"]
    data$Name_2[data$IndivID %in% phsistersid] <- "Paternal Half-Sister"
    
    mhsistersid <- data$IndivID[data$FathID != fatherid & data$MothID == motherid & data$Sex == "F"]
    data$Name_2[data$IndivID %in% mhsistersid] <- "Maternal Half-Sister"
  }
  
  # Get Half-Brothers
  if("Half-Brother" %in% option_relatives){
    phbrothersid <- data$IndivID[data$FathID == fatherid & data$MothID != motherid & data$Sex == "M"]
    data$Name_2[data$IndivID %in% phbrothersid] <- "Paternal Half-Brother"
    
    mhbrothersid <- data$IndivID[data$FathID != fatherid & data$MothID == motherid & data$Sex == "M"]
    data$Name_2[data$IndivID %in% mhbrothersid] <- "Maternal Half-Brother"
  }
  
  # Check if done - if so finish
  if(!"REMOVE" %in% data$Name_2) return(data)
  
  # Get grandchildren
  # Get granddaughter
  if("Granddaughter" %in% option_relatives){

    gdaughtersid <- data$IndivID[(data$MothID %in% daughtersid | data$FathID %in% sonsid) & data$Sex == "F"]
    data$Name_2[data$IndivID %in% gdaughtersid] <- "Granddaughter"
    
  }
  
  # Get grandson
  if("Grandson" %in% option_relatives){
    
    gsonsid <- data$IndivID[(data$MothID %in% daughtersid | data$FathID %in% sonsid) & data$Sex == "M"]
    data$Name_2[data$IndivID %in% gsonsid] <- "Grandson"
    
  }
  
  
  # Remove family members not needed
  if(remove){
    data <- data |>
      filter(Name_2 != "REMOVE")
  }
  
  return(data)
  
}

# data_pedigree <- read.csv("Z:/Generations/Projects/BOADICEA/tempdata/famsRF.csv")
# 
# start.time = Sys.time()
# cleaned_data_pedigree <- data_pedigree |>
#   group_by(FamID) |>
#   do(clean_family_data(., option = "All"))
# end.time = Sys.time()
# 
# print((end.time - start.time))
