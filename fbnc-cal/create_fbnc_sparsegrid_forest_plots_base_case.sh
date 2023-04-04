#!/usr/bin/env bash

#
# #########################
# Purpose: Create and build a sparse grid run for FATES SP
# Author: Jessica Needham
# Date: March, 2023
# #########################
# #########################
# Notes: Co-opted from Adrianna Foster's scripts which were co-opted from 
#  Keith Oleson's script for the CLM5 PPE (/glade/work/oleson/PPE/setup_run_PPE_BGC.csh)

#==============================================================
# Parameters: file names and directories, etc.
#==============================================================

TAG=fbnc_base                 ## used to create case name
CASEDIR=/compyfs/need138/elm_runs/calibration  ## case directory location
SRCDIR=/qfs/people/need138/E3SM                           ## CTSM code directory
OUT_DIR=/compyfs/need138/elm_runs/calibration                 ## Output directory
USER_MODS_DIR=/qfs/people/need138/fates-fbnc-cal/user_mod_dir/fates_fbnc
#==============================================================
# Step 1. Set up case name
#==============================================================


## Get ELM and FATES git versions - these will go into case name
cd ${SRCDIR}
githashelm=`git log -n 1 --format=%h`

cd components/elm/src/external_models/fates
githashfates=`git log -n 1 --format=%h`

## Create case name with elm and fates githash
case_name=${CASEDIR}/${TAG}_${githashelm}_${githashfates}.`date +"%Y-%m-%d"`

## Define CIME directory
base_dir=${SRCDIR}/cime/scripts
cd ${base_dir}


#==============================================================
# Step 2. Create the case and update parameters/files
#==============================================================
rm -r ${case_name}

./create_newcase --case ${case_name} --compset  2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SGLC_SWAV --res f19_f19 --project e3sm --output-root ${OUT_DIR} --mach compy --compiler intel --user-mods-dirs ${USER_MODS_DIR}

cd ${case_name}



./case.setup
./preview_namelists
./case.build
