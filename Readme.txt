Run the model normally by using qsub ANHA4-EXPT1.ksh, 
which calls the NEMO *.ksh file (/home/chako/RUN_TOOLS/nemo_jasper_v3.4_interannual_expt1.ksh).



The NEMO *.ksh file calls the DA *.ksh file with the following line:

## [5.2*] begin Data Assimilation cycle
#  =======================================================
/home/chako/DA_EXPT1/da_expt1.ksh

DA constructs the background file from the restart files; 
   reads in observation;
   calculates W matrix for generating an analysis file;
   update the restart files with the newly generated analysis file.

Next, NEMO restarts with the updated restart files, and another cycle of DA begins...
