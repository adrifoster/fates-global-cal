# FATES PPE Scripts and Tools

This folder is for scripts, parameter sets, and tools related to FATES PPE experiments.

The file *SP_PPE_parameters.csv* is a file similar to the [one](https://docs.google.com/spreadsheets/d/1OtkaO_uAmafWKR9kgtRC2Ge6d6fkhymngSpben5SJ_Q/edit) created for the CLM5 PPE. @adrifoster mostly created this by hand and by looking at the CLM5 PPE values and FATES parameter file and code. Columns are as follows:

* **fates_parameter**: FATES parameter name
* **clm_parameter**  : corresponding CLM parameter name (if any)
* **min**            : minimum code or value (e.g., '50percent', 'pft' - meaning we have a pft-specific value in a **param_lists** file)
* **max**            : maximum code or value
* **units**          : parameter units
* **dim**            : parameter dimension (e.g., 'pft', 'global')
* **group**          : parameter category, just for informations sake
* **description**    : parameter long name

The parameter lists in the directory **param_lists** are taken from the CLM PPE experiment - using their [parameter file](https://docs.google.com/spreadsheets/d/1OtkaO_uAmafWKR9kgtRC2Ge6d6fkhymngSpben5SJ_Q/edit). These just set up PFT-specific minimum and maximum values for specific parameters. The file *clm_fates_pfts.csv* also sets up a match between the FATES pft name and the CLM pft name.

The R script *CreatePFTParamListsPPE.R* uses the files in **param_lists** to create an overarching file called *PFT_params.csv* (inside **param_lists** by default).

The R script *CreateParamSetsPPE.R* uses these files to create parameter sets (along with FATES parameter creation tools) inside a specified directory.
