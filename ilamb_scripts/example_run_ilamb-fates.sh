#!/bin/bash

#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH -J example_job_name
#SBATCH -A e3sm
#SBATCH -o ilamb_job.o%j


# for use on nersc/e3sm machines 
source /share/apps/E3SM/conda_envs/load_latest_e3sm_unified_compy.sh

# change this to the place you run ILAMB
export ILAMB_ROOT=/compyfs/need138/ILAMB
 
srun -n 24 ilamb-run --config elm_fates_RCmodes_nospinup.cfg --model_root $ILAMB_ROOT/MODELS/ --models spmode spmode_JH fixedbiognocomp fixedbiognocomp_JH fixedbiogcomp fixedbiogcomp_JH full full_JH full_JH_spitfire --regions global --filter .elm.h0.  --model_setup example_model_setup.txt


# --clean - if you want  to overwrite existing ILAMB run for these model data comparisons
# --model_setup -   points to our file that shifts the start dates of the models to  be within the  range  of the data 
# --config - points to our .cfg file with all the confrontations
# --models - list all the models to include


# run this script with sbatch example_run_ilamb-fates.sh

# to look at results:
# ilamb creates a folder  called _build.  Copy this to a directory with with web viewing options. 
#  on cori /global/cfs/cdirs/e3sm/www/username    viewed from  https://portal.nersc.gov/cfs/e3sm/username
# on compy /compyfs/www/username  viewed from https://compy-dtn.pnl.gov/username

# note you might need to give  read and execute permissions  to these folders to be able to view them online
