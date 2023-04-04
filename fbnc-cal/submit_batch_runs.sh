#!/bin/sh

#SBATCH -N 2
#SBATCH --acount=e3sm
#SBATCH -t 06:00:00
#SBATCH --job-name=bundle-fbnc
#SBATCH -o sout.%j
#SBATCH -e serr.%j


./create_fbnc_clones "fates_alloc_storage_cushion" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_alloc_storage_cushion" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_grperc" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_grperc" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_maintresp_nonleaf_baserate" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_maintresp_nonleaf_baserate" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_maintresp_reduction_intercept" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_maintresp_reduction_intercept" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_mort_bmort" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_mort_bmort" "min" --no-batch -v >&bsubmitout.txt & 

./create_fbnc_clones "fates_mort_disturb_frac" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_mort_disturb_frac" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_mort_scalar_cstarvation" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_mort_scalar_cstarvation" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_mort_scalar_hydrfailure" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_mort_scalar_hydrfailure" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_mort_understorey_death" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_mort_understorey_death" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_turnover_branch" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_turnover_branch" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_turnover_leaf" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_turnover_leaf" "min" --no-batch -v >&bsubmitout.txt &

./create_fbnc_clones "fates_wood_density" "max" --no-batch -v >&bsubmitout.txt &
./create_fbnc_clones "fates_wood_density" "min" --no-batch -v >&bsubmitout.txt &

wait

echo "Done!"
                                                                                                       
                                                                                                       
                                          
