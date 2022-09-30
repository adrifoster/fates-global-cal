#!/bin/sh

#SBATCH -N 2
#SBATCH --account=e3sm
#SBATCH -t 01:00:00
#SBATCH --job-name=bundlecompile
#SBATCH -o sout.%j
#SBATCH -e serr.%j


#  how many ensemble members
ninst=2

run_elm_fates() {
 
# =======================================================================================
#
# USER SETTINGS
# USER MAY ALSO WANT TO ADJUST XML CHANGES, AND NAMELIST ARGUMENTS
# =======================================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV
export RES=f45_f45
export MACH=compy        # Name your machine
export COMPILER=intel    # Name your compiler
export PROJECT=e3sm      # Name your project

export TAG="ensemble_$1"              # User defined tag to differentiate runs
export CASEROOT=/compyfs/need138/elm_runs  # where should the run be built 

# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
#DIN_LOC_ROOT=/global/scratch/users/jfneedham/CESM_Inputdata/
#DIN_LOC_ROOT_FORC=${DIN_LOC_ROOT}/atm/datm7

export CIMEROOT=/qfs/people/need138/E3SM/cime/scripts  # point to E3SM/cime/scripts 

cd ${CIMEROOT}

export CIME_HASH=`git log -n 1 --pretty=%h`    # useful to record this in case of errors trying to reproduce  runs
export ELM_HASH=`(cd ../../components/elm/src;git log -n 1 --pretty=%h)`  # added to run name
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`  # added to run name
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASEROOT}/${TAG}.${GIT_HASH}.${TAG}.`date +"%Y-%m-%d"`  # added to run name

# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT}


cd ${CASE_NAME}


# SPECIFY RUN TYPE PREFERENCES (USERS WILL CHANGE THESE)
# =================================================================================

#./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_FORCE}
#./xmlchange DIN_LOC_ROOT=$DIN_LOC_ROOT

./xmlchange DEBUG=FALSE
./xmlchange STOP_N=2
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=2
./xmlchange RUN_STARTDATE='2000-01-01'
./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange JOB_QUEUE=slurm
./xmlchange RESUBMIT=1

# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT='$CASEROOT/run'
./xmlchange RUNDIR=${CASE_NAME}/run

# Here we tell it to use an  existing  case
./xmlchange EXEROOT=/compyfs/need138/elm_runs/spmode_JH_params.Eaf1f7c2-F08d429d.2022-09-02/bld
./xmlchange BUILD_COMPLETE=TRUE


# MODIFY THE CLM NAMELIST (USERS MODIFY AS NEEDED)

cat >> user_nl_elm <<EOF
fates_paramfile='/qfs/people/need138/RCmodes/Parameter_files/fates_params_spmode_$1.nc'
use_fates_sp = .true.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
EOF

./case.setup
./case.submit

}


# Loop through the parameter files and build and submit each case
# assumes parameter files are name_number.nc e.g. 
# fates_params_spmode_1.nc fates_params_spmode_2.nc etc

counter=1

while [ $counter -le $ninst ]
do
    run_elm_fates $counter --no-batch -v >&bsubmitout.txt &
    echo $counter 
    ((counter++))
done

wait

echo "Done!"
