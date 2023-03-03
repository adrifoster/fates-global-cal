#!/bin/sh
# =======================================================================================
#
# USER SETTINGS
# USER MAY ALSO WANT TO ADJUST XML CHANGES, AND NAMELIST ARGUMENTS
# =======================================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV
export RES=ELM_USRDAT
export MACH=compy                                             # Name your machine
export COMPILER=intel                                            # Name your compiler
export PROJECT=e3sm

export TAG='DBEN_bci_trendy_ens_datmstreams'                 # User defined tag to differentiate runs
export CASEROOT=/compyfs/need138/elm_runs/DBEN   # Where the build is generated (probably on scratch partition)

export SITE_NAME=BCI                              # Name of folder with site data
export SITE_BASE_DIR=/compyfs/inputdata/atm/datm7/DBEN_TRENDY   # Where is the site folder located? (SITE_NAME)
export ELM_USRDAT_DOMAIN=domain.lnd.1x1pt-BCI_v_c20220727_navy.nc   # Name of domain file in data/${SITE_DIR}/
export ELM_USRDAT_SURDAT=surfdata_1x1pt-BCI_v_c20220727.nc  # Name of surface file in data/${SITE_DIR}/
#export DIN_LOC_ROOT_FORCE=${SITE_BASE_DIR}/${SITE_NAME}           # Is this point to the correct location? (GL)
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}/${SITE_NAME}
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}/${SITE_NAME}

export DATM_START=1991
export DATM_STOP=2020

ninst=2

# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
export SOURCE_DIR=/qfs/people/need138/E3SM/cime/scripts
cd ${SOURCE_DIR}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd  ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASEROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`


# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT} --ninst=$ninst --multi-driver

cd ${CASE_NAME}

# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLMCRUNCEP
./xmlchange ELM_USRDAT_NAME=${SITE_NAME}
#./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_FORCE}

./xmlchange CIME_OUTPUT_ROOT=${CASE_NAME}

#./xmlchange PIO_VERSION=2

# For constant CO2
./xmlchange CCSM_CO2_PPMV=412
./xmlchange DATM_CO2_TSERIES=none
./xmlchange ELM_CO2_TYPE=constant


# SPECIFY PE LAYOUT FOR SINGLE SITE RUN (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_LND=1
./xmlchange NTASKS_ROF=1
./xmlchange NTASKS_ESP=1
./xmlchange ROOTPE_ATM=0
./xmlchange ROOTPE_CPL=0
./xmlchange ROOTPE_GLC=0
./xmlchange ROOTPE_OCN=0
./xmlchange ROOTPE_WAV=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_LND=0
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ESP=0
./xmlchange NTHRDS_ATM=1
./xmlchange NTHRDS_CPL=1
./xmlchange NTHRDS_GLC=1
./xmlchange NTHRDS_OCN=1
./xmlchange NTHRDS_WAV=1
./xmlchange NTHRDS_ICE=1
./xmlchange NTHRDS_LND=1
./xmlchange NTHRDS_ROF=1
./xmlchange NTHRDS_ESP=1

# SPECIFY RUN TYPE PREFERENCES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange DEBUG=FALSE
./xmlchange STOP_N=50
./xmlchange RUN_STARTDATE='1991-01-01'
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=50
./xmlchange RESUBMIT=1

./xmlchange DATM_CLMNCEP_YR_START=${DATM_START}
./xmlchange DATM_CLMNCEP_YR_END=${DATM_STOP}

./xmlchange JOB_WALLCLOCK_TIME=00:29:00
./xmlchange JOB_QUEUE=short --force

# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT='$CASEROOT/run'
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld

./case.setup

# MODIFY THE CLM NAMELIST (USERS MODIFY AS NEEDED)

for x in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    ending=$x
    cat > user_nl_elm_${expstr} <<EOF
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
fates_paramfile='/qfs/people/need138/bci_params_lhc/Ensemble_params/trimmed/fates_params_bci_ens_${ending}.nc'
fates_parteh_mode = 1
hist_empty_htapes=.true.
hist_nhtfrq = -8760
use_fates=.true.
use_fates_nocomp=.false.
use_fates_logging=.false.
use_fates_planthydro=.false.
use_fates_ed_prescribed_phys=.false.
hist_fincl1='FATES_VEGC_PF', 'FATES_STRUCTC', 'FATES_NPLANT_SZ', 'FATES_CROWNAREA_PF', 
'FATES_AGSAPWOOD_ALLOC_SZPF', 'FATES_AGSTRUCT_ALLOC_SZPF','FATES_VEGC_ABOVEGROUND_SZPF', 
'FATES_MORTALITY_CSTARV_CFLUX_PF','FATES_MORTALITY_CFLUX_PF', 
'FATES_MORTALITY_BACKGROUND_SZPF', 'FATES_MORTALITY_HYDRAULIC_SZPF', 'FATES_MORTALITY_CSTARV_SZPF', 
'FATES_MORTALITY_IMPACT_SZPF', 'FATES_MORTALITY_TERMINATION_SZPF', 'FATES_MORTALITY_FREEZING_SZPF', 
'FATES_NPLANT_SZPF','FATES_LAI_CANOPY_SZPF','FATES_BASALAREA_SZPF', 'FATES_MORTALITY_CANOPY_SZPF', 
'FATES_MORTALITY_USTORY_SZPF', 'FATES_NPLANT_CANOPY_SZPF', 'FATES_MORTALITY_USTORY_SZPF', 
'FATES_LAI_USTORY_SZPF', 'FATES_LAI_CANOPY_SZPF', 
'FATES_ABOVEGROUND_PROD_SZPF', 'FATES_ABOVEGROUND_MORT_SZPF'
use_fates_nocomp=.false.
use_fates_logging=.false.
EOF

done

#--------- point to climate forcing data ----  
for x in `seq 1 1 $ninst`; do
expstr=$(printf %04d $x)
echo $expstr 

cp /compyfs/inputdata/atm/datm7/DBEN_TRENDY/BCI/atm_forcing.datm7.cruncep_qianFill.0.5d.V4.c130305/Solar6HrlyNew/user_datm.streams.txt.CLMCRUNCEP.Solar user_datm.streams.txt.CLMCRUNCEP.Solar_${expstr} 
cp /compyfs/inputdata/atm/datm7/DBEN_TRENDY/BCI/atm_forcing.datm7.cruncep_qianFill.0.5d.V4.c130305/Precip6HrlyNew/user_datm.streams.txt.CLMCRUNCEP.Precip user_datm.streams.txt.CLMCRUNCEP.Precip_${expstr}
cp /compyfs/inputdata/atm/datm7/DBEN_TRENDY/BCI/atm_forcing.datm7.cruncep_qianFill.0.5d.V4.c130305/TPHWL6HrlyNew/user_datm.streams.txt.CLMCRUNCEP.TPQW user_datm.streams.txt.CLMCRUNCEP.TPQW_${expstr}
done


./case.build
./case.submit --skip-preview-namelist
