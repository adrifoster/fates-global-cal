#
# #########################
# Purpose: Create pft-specific min/max values for FATES parameters
# Author: Adrianna C. Foster
# Date: April, 2022
# R version 4.1.1 (2021-08-10) 'Kick Things'
# #########################
# #########################
# Input format: csv, nc
# Output format: csv
# #########################

setwd('/Users/afoster/Documents/ncar/fates/PPE')

library(dplyr)
library(ncdf4)

## Script parameters -----------------------------------------------------------
fates_param_base_file <- 'param_file_base.nc'      ## base FATES parameter file name
param_list_dir <- 'param_lists'                    ## directory for parameter lists
pft_match_file <- 'param_lists/clm_fates_pfts.csv' ## csv file matching FATES pft names to CLM pft names

## parameters to grab
params <- c('taulnir', 'taulvis', 'rholnir',
            'rholvis', 'xl', 'medlynslope', 'sla')
## Actual program --------------------------------------------------------------

## fates pfts
param_base <- nc_open(fates_param_base_file)
pfts <- trimws(ncvar_get(param_base, "fates_pftname"))
nc_close(param_base)

## match CLM pfts to FATES pfts
pft_df <- read.csv(pft_match_file)

## loop through individual csvs from CLM5 parameter list
## to get pft-specific min/max values
param_out <- data.frame()
for (i in 1:length(params)) {
  
  ## min/max values for this parameter for CLM pfts
  file <- paste0(param_list_dir, '/', params[i], '_pft_params.csv')
  df <- read.csv(file)
  
  ## create empty dataframe
  pft_out <- data.frame(pft_index = seq(1, length(pfts)),
                        pft = pfts)
  pft_out$param <- params[i]
  pft_out$min <- NA
  pft_out$max <- NA
  
  ## loop through FATES pfts
  for (j in 1:length(pfts)){
    
    # find matching clm pft(s)
    clm_pft <- unlist(strsplit(pft_df[which(pfts[j] == pft_df$fates_pft), 
                                            'clm_pft'], ','))
    
    ## subset CLM parameter df to these pfts, may be more than one
    sub <- filter(df, pftname %in% clm_pft)
    
    ## get min and max values
    minv <- min(sub[,paste0(params[i], '_min')])
    maxv <- max(sub[,paste0(params[i], '_max')])
    pft_out[j, 'min'] <- minv
    pft_out[j, 'max'] <- maxv
  }
  param_out <- rbind(param_out, pft_out)
  
}

## write final file
write.csv(param_out, paste0(param_list_dir, '/PFT_params.csv'), row.names = F,
          quote = F)
