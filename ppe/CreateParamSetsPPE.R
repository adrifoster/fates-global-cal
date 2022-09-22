#
# #########################
# Purpose: Create sets of parameter values for a FATES PPE
# Author: Adrianna C. Foster
# Date: April, 2022
# R version 4.1.1 (2021-08-10) 'Kick Things'
# #########################
# #########################
# Input format: csv, nc
# Output format: csv
# #########################

setwd('/Users/afoster/Documents/ncar/fates/PPE')

library(ncdf4)
library(dplyr)

## Functions -------------------------------------------------------------------
get_param_df <- function(param_base, param_changes){
  ## create a data frame for parameter changes
  ## Inputs:
  ##        param_base:       base FATES parameter file
  ##        param_changes:    csv of parameters to change
  
  
  ## get number of pfts
  pfts <- trimws(ncvar_get(param_base, "fates_pftname"))
  num_pfts <- length(pfts)
  
  ## loop through parameters to change
  param_df <- data.frame()
  for (i in 1:nrow(param_changes)){
    
    ## pull out parameter name, min/max code or value, and variable dimension
    parameter <- param_changes[i, 'fates_parameter']
    min <- param_changes[i, 'min']
    max <- param_changes[i, 'max']
    var_dim <- param_changes[i, 'dim']
    
    ## get default value/s for this parameter
    default <- ncvar_get(param_base, parameter)
    
    ## get min values
    min_vals <- get_vals(parameter = parameter, min_max = min, type = 'min', 
                         pft_vals = pft_vals, param_base = param_base, 
                         num_pfts = num_pfts, var_dim = var_dim)
    
    ## get max values
    max_vals <- get_vals(parameter = parameter, min_max = max, type = 'max', 
                         pft_vals = pft_vals, param_base = param_base, 
                         num_pfts = num_pfts, var_dim = var_dim)
    
    ## we need to worry about dimensionality of parameters
    if (var_dim == 'pft'){
      
      ## pft-specific parameter - make df with pft-bounds
      df <- data.frame(parameter = rep(rep(parameter, num_pfts), 2), 
                       pft = rep(seq(1, num_pfts), 2),
                       default = rep(default, 2),
                       val = c(min_vals, max_vals),
                       type = rep(c('min', 'max'), each = num_pfts))
      
    } else if (var_dim == 'global'){
      
      ## global parameter - just one min/max number
      df <- data.frame(parameter = rep(parameter, 2), 
                       pft = 'none',
                       default = rep(default, 2),
                       val = c(min_vals, max_vals),
                       type = c('min', 'max'))
      
    } else if (var_dim == 'global_dim') {
      
      ## global plus some other dimension - working around this 
      ## by collapsing with an underscore
      df <- data.frame(parameter = rep(parameter, 2), 
                       pft = 'none',
                       default = rep(paste0(default, collapse = '_'), 2),
                       val = c(paste0(min_vals, collapse = '_'), 
                               paste0(max_vals, collapse = '_')),
                       type = c('min', 'max'))
      
    } else if (var_dim == 'pft_dim') {
      
      def <- apply(X = default, MARGIN = 1, FUN = paste0, collapse = '_')
      minvals <- apply(X = min_vals, MARGIN = 1, FUN = paste0, collapse = '_')
      maxvals <- apply(X = max_vals, MARGIN = 1, FUN = paste0, collapse = '_')
      
      df <- data.frame(parameter = rep(rep(parameter, num_pfts), 2), 
                       pft = rep(seq(1,12), 2),
                       default = rep(def, 2),
                       val = c(minvals, maxvals),
                       type = rep(c('min', 'max'), each = num_pfts))
    }
    df$var_dim <- var_dim
    param_df <- rbind(param_df, df)
  }
  
  return(param_df)
  
}

get_vals <- function(parameter, min_max, type, pft_vals, param_base,
                     num_pfts, var_dim){
  ## grab min or max parameter values for a specific parameter
  ## Inputs:
  ##        parameter:  fates parameter name
  ##        min_max:    min or max value from input dataframe
  ##        type:       'min' or 'max'
  ##        pft_vals:   pft_vals:  data frame with pft-specific min/max values
  ##        param_base: default FATES parameter file (netcdf)
  ##        num_pfts:   number of pfts 
  ## Outputs:
  ##        vals:    min or max values
  
  ## min/max is a code or a number
  if (min_max == 'pft'){
    
    ## we want to grab pft-specific min/max values
    vals <- get_pft_val(parameter = parameter, type = type, pft_vals = pft_vals)
    
  } else if (min_max == '50percent'){
    
    ## we want to apply 50% percentage min/max
    vals <- get_percentage(parameter = parameter, type = type, 
                           param_base = param_base, pct = 0.5)
    
  } else if (min_max == '100percent'){
    
    ## we want to apply 100% percentage min/max
    vals <- get_percentage(parameter = parameter, type = type,
                           param_base = param_base, pct = 1.0)
    
  } else {
    
    ## otherwise we are using a specific number in csv file
    ## now we have to be careful of dimensions
    
    if (var_dim == 'global'){
      
      ## global parameters are just one number
      vals <- as.numeric(min_max)
    
      } else if (var_dim == 'pft'){
      
      ## pft have dimension of pft
      vals <- rep(as.numeric(min_max), num_pfts)
    
      } else {
      
      ## otherwise it's a weird dimension  so set it up to match the
      ## base dimension
      def <- ncvar_get(param_base, parameter)
      def[] <- as.numeric(min_max)
      vals <- def
    }
  }
  
  return(vals)
  
}

get_pft_val <- function(parameter, type, pft_vals){
  ## grab the correct min or max values from the pft-specific list
  ## Inputs:
  ##        parameter: fates parameter name
  ##        type:      'min' or 'max'
  ##        pft_vals:  data frame with pft-specific min/max values
  ## Outputs:
  ##        values:    pft-specific min or max values
  
  ## to match parameters with param values in df
  param_df <- data.frame(parameter = c('fates_taulnir', 'fates_taulvis', 
                                       'fates_rholnir', 'fates_rholvis',
                                       'fates_leaf_xl', 'fates_leaf_slatop',
                                       'fates_leaf_stomatal_slope_medlyn'),
                         param = c('taulnir', 'taulvis',
                                   'rholnir', 'rholvis',
                                   'xl', 'sla',
                                   'medylnslope'))
  
  ## grab the correct parameter name
  parm <- param_df[which(param_df$parameter == parameter), 'param']
  
  ## grab min or max values across all pfts
  values <- filter(pft_vals, param == parm)[,type]
  
  return(values)
  
}

get_percentage <- function(parameter, type, param_base, pct) {
  ## grab percent above (max) or below (min) the default parameter values
  ## for a specific parameter
  ## Inputs:
  ##        parameter:  fates parameter name
  ##        type:       'min' or 'max'
  ##        param_base:  default FATES parameter file (netcdf)
  ## Outputs:
  ##        vals:    pft-specific min or max values
  
  ## get default values
  base_values <- ncvar_get(param_base, parameter)
  
  ## get either percent above or below base value
  if (type == 'min') {
    vals <- base_values - base_values*pct
  } else if (type == 'max') {
    vals <- base_values + base_values*pct
  }
  
  return(vals)
  
}

create_paramfile_allpfts <- function(param, type, param_df,
                             fates_src_path, fates_param_orig, dim,
                             case_name, dir) {
  ## create a new parameter file for FATES - changing all pfts at the 
  ## same time
  ## this uses the modify_fates_paramfile.py python script
  ## Inputs:
  ##        param:            fates parameter name
  ##        type:             type of case to run (i.e. min, max, etc.)
  ##        param_df:         parameter set df
  ##        fates_src_path:   path to the fates source code
  ##        fates_param_orig: FATES parameter cdl file name
  ##        dim:              parameter dimension (e.g. 'pft', 'global')
  ##        case_name:        naming tag for parameter file
  ##        dir:              directory to place parameter files

  ## output file name
  fates_params_case <- file.path(dir, paste0("fates_param_", case_name,".nc"))
  
  ## create the file
  system(paste("ncgen -o", fates_params_case, fates_params_orig, sep=" "))
  
  ## python code to modify file
  modify_params_py <- file.path(fates_src_path, "tools",
                                "modify_fates_paramfile.py")
  
  ## grab the correct type and parameter from the parameter set df
  sub <- filter(param_df, type == min_max & parameter == param)
  
  if (dim %in% c('pft', 'pft_dim')){
    
    ## we are going to change all pfts at once for now
    for (i in 1:nrow(sub)){
      command <- paste('python3', modify_params_py, 
                       "--var", param,
                       "--pft", i,
                       "--val", paste0(unlist(strsplit(sub[i, 'val'], 
                                                       split = '_')), 
                                       collapse = ','), 
                       "--fin", fates_params_case, 
                       "--fout", fates_params_case, 
                       "--O", 
                       sep = " ")
      system(command)
    }
  } else {
    
    ## just a global value
    val <- paste0(unlist(strsplit(sub[1, 'val'], split = '_')), collapse = ',')
    
    command <- paste('python3', modify_params_py, 
                     "--var", param,
                     "--val", val, 
                     "--fin", fates_params_case, 
                     "--fout", fates_params_case, 
                     "--O", 
                     sep = " ")
    system(command)
  }
  
  
}


make_all_paramfiles_ppe <- function(param_df, fates_src_path,
                                fates_param_orig, dir, by_pft = F){
  ## create a set of FATES parameters from a input file of values, pfts, names 
  ## Inputs:
  ##        param_df:         parameter set df
  ##        fates_src_path:   path to the fates source code
  ##        fates_param_orig: FATES parameter cdl file name
  ##        dir:              directory to place parameter files
  ##        by_pft:           make one pft file to change all pfts values for each parameter
  
  ## right now we just change all pfts for each parameter at once... 
  ## will probably need to update this eventually
  if (!by_pft){
    
    ## get list
    param_list <- dplyr::select(param_df, parameter, type, var_dim) %>%
      distinct_all()
    
    ## create a case name
    param_list$case.name <- seq(1, nrow(param_list))
    
    ## loop through list of parameters and make 1 parameter file for 
    ## each
    for (i in 1:nrow(param_list)){
      create_paramfile_allpfts(param = param_list[i, 'parameter'], 
                               type = param_list[i, 'type'], 
                               param_df = param_df, 
                               fates_src_path = fates_src_path, 
                               fates_param_orig = fates_param_orig, 
                               dim = param_list[i, 'var_dim'],
                               case_name = param_list[i, 'case.name'],
                               dir = dir)
    }

  }
  
  ## write a file to tell you what the case names are
  param_key <- reshape2::dcast(param_list, parameter ~ type, 
                               value.var = 'case.name')
  colnames(param_key) <- c('parameter', 'max_case', 'min_case')
  write.csv(param_key, paste0(dir, '/param_file_key.csv'), row.names = F)

}

## Script parameters -----------------------------------------------------------
fates_param_base_file <- 'param_file_base.nc'   ## base FATES parameter file name

## FATES cdl file
fates_params_orig <- paste0('/Users/afoster/Documents/ctsm/ctsm_fates/src/',
                            'fates/parameter_files/fates_params_default.cdl')
## FATES source code
fates_src_path <- '/Users/afoster/Documents/ctsm/ctsm_fates/src/fates'

## file with PFT-specific min/max values - created with CreatePFTParamListsPPE.R
pft_values_file <- 'param_lists/PFT_params.csv' 

## csv with parameters to modify and by how much, and other information
## this was created by hand using information from FATES parameter file
## and FATES code, along with input from CLM PPE
param_list_file <- 'SP_PPE_parameters.csv'  

param_set_dir <- 'param_sets' # directory for parameter set

## Actual program --------------------------------------------------------------

## fates parameter file
param_base <- nc_open(fates_param_base_file)

## parameters to change
param_changes <- read.csv(param_list_file)

## pft-specific min/max values
pft_vals <- read.csv(pft_values_file)

## get output of parameter values to change to
param_df <- get_param_df(param_base, param_changes)
write.csv(param_df, paste0(param_set_dir, '/PPE_min_max.csv'), row.names = F)

## make all the parameter files
make_all_paramfiles_ppe(param_df, fates_src_path, fates_param_orig, 
                        'ppe_param_files')


