#!/bin/ksh
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##
##                                                                     ##
##         SCRIPT TO RUN A DRAKKAR SIMULATION on ZAHIR                 ##
##								       ##
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##
##  full rewrite for UQBAR, J.M. Molines (July, 2002)                  ##
##  rewrite for EOSF, Anne de Miranda (Marc, 2003)                     ##
##  Port from uqbar to zahir in loadleveller (J.M. Molines, may 2003)  ##
##                                                                     ##
##  For details and informations: Anne.de-Miranda@hmg.inpg.fr          ##
##   or ( for zahir )           Jean-Marc.Molines@hmg.inpg.fr          ##
##                                                                     ##
#########################################################################
####################    server info section     #########################
#                         PBS directives                                #

#PBS -N ANHA4-EXPT1

# This is the shell that PBS will use to execute your script file.
#PBS -S /bin/bash

# The requested queue
##PBS -q qs

# host machine
##PBS -l host=synapse

## Number of cpus required by the job
##PBS -l feature=X5675
#PBS -l nodes=12:ppn=4
#PBS -l pmem=2000MB
#PBS -l naccesspolicy=singlejob
#PBS -l walltime=24:00:00

# email  when the job [b]egins and [e]nds, or is [a]borted
#PBS -m bea

#PBS -M chiongheng.chen@gmail.com

##################    model configue section     ########################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BAT=1                           # copy (link) bathymetry files
gr=1                            # copy(link) coordinate file (model-grid)
TEMP=1                          # 3D-potential temperature data
SAL=1                           # 3D-salinity data
FLXCORE=1                       # Atmospheric-forcing from CORE
ICE=1                           # backup/copy(link) ice restart files
# recent added new flags
WEIGHT=1                        # weight file for on-the-fly-interpolation
IsIA=1                          # Inter-annual simulation
isKEYNETCDF=1                   # newly added to set the model to run netcdf

FLXSET1=0                       # Atmospheric-forcing from dataset1
MESH=0                          # generating mesh/mask files
REL=0                           # customized relax/restore file? Not used in this version
RFLOAT=0                        # restart float file (flodom.F90)
IFLOAT=0                        # initial float file (flodom.F90)
MOOR=0                          # Mooring position
bfr=0                           # bottom friction
geo=0                           # geothermal heating
COEF2D=0                        # Lateral Viscosity Coefficient
AGRIF=1
NEST=1
TOP=0
DELTEMP=1                       # Delete files under TMP folder
########################################################################
AUSER=chako
CONFIG=ANHA4
CASE=EXPT1

CONFIG_CASE=${CONFIG}-${CASE}

NCPUS=${PBS_NP}
BUFFER_LENGTH=4000000                    # not sure, maybe for some libaries
export OMPI_TMPDIR=${TMPDIR}             # used for mpirun
TMPDIR=$HOME/TMP_RUN_${CONFIG_CASE}.$$   # work folder
WORKDIR=$HOME

P_S_DIR=${WORKDIR}/${CONFIG}/${CONFIG_CASE}-S          # backup model output
P_R_DIR=${WORKDIR}/${CONFIG}/${CONFIG_CASE}-R          # backup restart files
P_I_DIR=${WORKDIR}/${CONFIG}-I                         # path of input data files

P_CTL_DIR=$HOME/RUN_${CONFIG}/${CONFIG_CASE}/CTL
P_EXE_DIR=$HOME/RUN_${CONFIG}/${CONFIG_CASE}/EXE
P_UTL_DIR=$HOME/UTILS
P_AGRIF_DIR=$HOME/RUN_${CONFIG}/${CONFIG_CASE}/AGRIF
EXEC=$HOME/RUN_${CONFIG}/${CONFIG_CASE}/EXE/opa

# set specific file names (data )                             ;   and their name in OPA9                       
#--------------------------------------------------------------------------------------------------------
BATFILE_LEVEL=                                                              ;  OPA_BATFILE_LEVEL=bathy_level.nc
BATFILE_METER=ANHA4_bathy_etopo1_gebco1_smoothed_coast_corrected_mar10.nc   ;  OPA_BATFILE_METER=bathy_meter.nc
#BATFILE_METER=CREG025_bathy_etopo1_gebco1_smoothed_coast_corrected_mar10.nc   ;  OPA_BATFILE_METER=bathy_meter.nc

COORDINATES=ANHA4_coordinates.nc                                            ;  OPA_COORDINATES=coordinates.nc
# if IsTSIA=0, script replace y0000 with current year automatically
#SubTS="/TS"    # sub-folder for TS, for inter-anuall, script will search file with "_y????" automatically
#TEMPDTA=votemper_phc3-creg025.nc             # inter-anuall: votemper_phc3-creg025_y????.nc
#SALDTA=vosaline_phc3-creg025.nc              #             : vosaline_phc3-creg025_y????.nc
#SSSDTA=sss_phc3-creg025.nc                   #             : sss_phc3-creg025_y????.nc
#SSTDTA=sst_phc3-creg025.nc                   #             : sst_phc3-creg025_y????.nc
SubTS=""; ## TEMPDTA=ANHA4_IC_T_200201.nc; SALDTA=ANHA4_IC_S_200201.nc; 

     TEMPDTA=ANHA4_IC_T_200201.nc         ; OPA_TEMPDTA=data_1m_potential_temperature_nomask.nc
     SALDTA=ANHA4_IC_S_200201.nc ; OPA_TEMPDTAM=data_1m_potential_temperature_nomask.nc


TSUVINI=1    # initial T,S,U,V,SSH
INITT=ANHA4_IC_T_200201.nc                                                              ; OPA_INITT=IC_T.nc               
INITS=ANHA4_IC_S_200201.nc                                                              ; OPA_INITS=IC_S.nc               
INITU=ANHA4_IC_U_200201.nc                                                              ; OPA_INITU=IC_U.nc               
INITV=ANHA4_IC_V_200201.nc                                                              ; OPA_INITV=IC_V.nc               
INITSSH=ANHA4_IC_SSH_200201.nc                                                          ; OPA_INITSSH=IC_SSH.nc

# surface solar radiation penetration
KRGB=kRGB61.txt                                                               ; OPA_KRGB=kRGB61.txt
CHLAFILE=ANHA4_chlaseawifs_c1m-99005_smooth.nc

#
ICEINI=ANHA4_ice_init_lim.nc                                                  ;  OPA_ICEINI=Ice_initialization.nc
ICEDMP=ANHA4_ice_damping_lim.nc                                               ;  OPA_ICEDMP=ice_damping.nc
RELAX=                                                                        ;  OPA_RELAX=relax.nc

# Forcing CORE
#   filenames here are for the climatology simulations
#   in inter-annual runs, a suffix, e.g., "_y1970" will be added automatically
WEIGHT=1; 
#SubCORE="/core2"    # sub-folder for core
#FLXWEIGHT=weight_bilinear_core2_creg025.nc   ; OPA_FLXWEIGHT=CORE_weight.nc
#PRECIP_CORE=prc_core2.nc                     ; OPA_PRECIP_CORE=precip.nc
#TAUX_CORE=u10_core2.nc                       ; OPA_TAUX_CORE=u10.nc
#TAUY_CORE=v10_core2.nc                       ; OPA_TAUY_CORE=v10.nc
#HUMIDITY_CORE=q10_core2.nc                   ; OPA_HUMIDITY_CORE=q10.nc
#SHORT_WAVE_CORE=swdn_core2.nc                ; OPA_SHORT_WAVE_CORE=radsw.nc
#LONG_WAVE_CORE=lwdn_core2.nc                 ; OPA_LONG_WAVE_CORE=radlw.nc
#TAIR_CORE=t10_core2.nc                       ; OPA_TAIR_CORE=t10.nc
#SNOW_CORE=snow_core2.nc                      ; OPA_SNOW_CORE=snow.nc

SubCORE="/CMC_GDPS"  # sub-folder for core
FLXWEIGHT=weight_bilinear_gdps_creg025.nc   ; OPA_FLXWEIGHT=CORE_weight.nc
PRECIP_CORE=precip_gdps.nc                  ; OPA_PRECIP_CORE=precip.nc
TAUX_CORE=u10_gdps.nc                       ; OPA_TAUX_CORE=u10.nc
TAUY_CORE=v10_gdps.nc                       ; OPA_TAUY_CORE=v10.nc
HUMIDITY_CORE=q2_gdps.nc                    ; OPA_HUMIDITY_CORE=q10.nc
SHORT_WAVE_CORE=qsw_gdps.nc                 ; OPA_SHORT_WAVE_CORE=radsw.nc
LONG_WAVE_CORE=qlw_gdps.nc                  ; OPA_LONG_WAVE_CORE=radlw.nc
TAIR_CORE=t2_gdps.nc                        ; OPA_TAIR_CORE=t10.nc
#SNOW_CORE=snow_gdps_from_core2_normal.nc                     ; OPA_SNOW_CORE=snow.nc
SNOW_CORE=precip_gdps.nc                    ; OPA_SNOW_CORE=snow.nc

RUNOFF=ANHA4_runoff_monthly_DaiTrenberth_Feb2015.nc   ;OPA_RUNOFF=runoff_1m_nomask.nc
#RUNOFF=runoff_daitren_monthly.nc                     ; OPA_RUNOFF=runoff_1m_nomask.nc
RUNOFF_mask=ANHA4_runoff_monthly_DaiTrenberth_Feb2015.nc   ; OPA_RUNOFF_mask=runoff_mask.nc
#RUNOFF_mask=ANHA4_runoff_mask_2014.nc                     ; OPA_RUNOFF_mask=runoff_mask.nc
RUNOFFWEIGHT=weight_bicubic_runoff_creg025.nc  ; OPA_RUNOFFWEIGHT=runoff_weight.nc
BFR=                                           ; OPA_BFR=bfeb2.nc
GEO=                                           ; OPA_GEO=geothermal_heating.nc
AHM2D=                                         ; OPA_AHM2D=ahmcoef

# Open Boundary data
#   filenames here are for the climatology simulations
#   in inter-annual runs, the file name will be renamed to obc data in current year automatically
#--------------------------------------------------------------------------------------------------------
SubOBC='/OBC2014'
EASTOBCTS=                                   ; OPA_EASTOBCTS=obc_east_TS_y0000m00.nc
EASTOBCU=                                    ; OPA_EASTOBCU=obc_east_U_y0000m00.nc
EASTOBCV=                                    ; OPA_EASTOBCV=obc_east_V_y0000m00.nc
WESTOBCTS=                                   ; OPA_WESTOBCTS=obc_west_TS_y0000m00.nc
WESTOBCU=                                    ; OPA_WESTOBCU=obc_west_U_y0000m00.nc
WESTOBCV=                                    ; OPA_WESTOBCV=obc_west_V_y0000m00.nc
NORTHOBCTS=ANHA4_north_TS_GLORYS2V3_y0000m00.nc      ; OPA_NORTHOBCTS=obc_north_TS_y0000m00.nc
NORTHOBCU=ANHA4_north_U_GLORYS2V3_y0000m00.nc        ; OPA_NORTHOBCU=obc_north_U_y0000m00.nc
NORTHOBCV=ANHA4_north_V_GLORYS2V3_y0000m00.nc        ; OPA_NORTHOBCV=obc_north_V_y0000m00.nc
SOUTHOBCTS=ANHA4_south_TS_GLORYS2V3_y0000m00.nc      ; OPA_SOUTHOBCTS=obc_south_TS_y0000m00.nc
SOUTHOBCU=ANHA4_south_U_GLORYS2V3_y0000m00.nc        ; OPA_SOUTHOBCU=obc_south_U_y0000m00.nc
SOUTHOBCV=ANHA4_south_V_GLORYS2V3_y0000m00.nc        ; OPA_SOUTHOBCV=obc_south_V_y0000m00.nc


## AGRIF FILE DEFINITIONS
if [ $AGRIF = 1 ]
  then
     BATFILE_LEVEL1=                          ; OPA_BATFILE_LEVEL1=1_bathy_level.nc
     BATFILE_METER1=1_AgrifBathyMeterOut.nc   ; OPA_BATFILE_METER1=1_bathy_meter.nc
#     BATFILE_METER1=1_CREG025_bathy_etopo1_gebco1_smoothed_coast_corrected_mar10.nc   ; OPA_BATFILE_METER1=1_bathy_meter.nc
#     COORDINATES1=1_CREG025_coordinates.nc                    ; OPA_COORDINATES1=1_coordinates.nc

     COORDINATES1=1_agrif_coord.nc                     ; OPA_COORDINATES1=1_coordinates.nc
#     TEMPDTA1=1_CREG025_glorys1v1_T.nc;
#     SALDTA1=1_CREG025_glorys1v1_S.nc;
#     SALDTA1=1_vosaline.nc;
     TEMPDTA1=1_votemper.nc         ; OPA_TEMPDTA1=1_data_1m_potential_temperature_nomask.nc
     TEMPDTAM1=1_votemper.nc        ; OPA_TEMPDTAM1=1_data_1m_potential_temperature_nomask.nc
     SALDTA1=1_vosaline.nc          ; OPA_SALDTA1=1_data_1m_salinity_nomask.nc
     SALDTAM1=1_vosaline.nc         ; OPA_SALDTAM1=1_data_1m_salinity_nomask.nc
     SSSDTA1=1_sss_phc3-creg025_monthly.nc       ; OPA_SSSDTA1=1_sss_1m.nc
     TAUX_CORE1=                    ; OPA_TAUX_CORE1=1_u10.nc
     TAUY_CORE1=                    ; OPA_TAUY_CORE1=1_v10.nc
     TAIR_CORE1=                    ; OPA_TAIR_CORE1=1_t10.nc
     PRECIP_CORE1=                  ; OPA_PRECIP_CORE1=1_precip.nc
     HUMIDITY_CORE1=                ; OPA_HUMIDITY_CORE1=1_q10.nc
     SHORT_WAVE_CORE1=              ; OPA_SHORT_WAVE_CORE1=1_radsw.nc
     LONG_WAVE_CORE1=               ; OPA_LONG_WAVE_CORE1=1_radlw.nc
     SNOW_CORE1=                    ; OPA_SNOW_CORE1=1_snow.nc
     RUNOFF1=1_ANHA12_runoff_monthly_DaiTrenberth_Jan2015.nc        ; OPA_RUNOFF1=1_runoff_1m_nomask.nc
#     RUNOFF1=1_ANHA12_runoff_monthly_DaiTrenberth_remapped.nc      ; OPA_RUNOFF1=1_runoff_1m_nomask.nc
#     RUNOFF_mask1=   ; OPA_RUNOFF_mask1=
#     RUNOFFWEIGHT1=    ; OPA_RUNOFFWEIGHT1=##runoff_weight.nc

     ICEINI1=1_ANHA12_ice_init_lim.nc                           ; OPA_ICEINI1=1_Ice_initialization.nc
     ICEDMP1=1_ANHA12_ice_init_lim.nc                           ; OPA_ICEDMP1=1_ice_damping.nc
     AGRIF_WEIGHT=1_weight_agrif_bilinear_core2_creg025.nc      ;  OPA_FLXWEIGHT1=AGRIF_weight.nc
     INITT1=1_ANHA12_IC_T.nc                                                  ; OPA_INITT1=1_IC_T.nc
     INITS1=1_ANHA12_IC_S.nc                                                  ; OPA_INITS1=1_IC_S.nc
     INITU1=1_ANHA12_IC_U.nc                                                  ; OPA_INITU1=1_IC_U.nc
     INITV1=1_ANHA12_IC_V.nc                                                  ; OPA_INITV1=1_IC_V.nc
     INITSSH1=1_ANHA12_IC_SSH.nc                                              ; OPA_INITSSH1=1_IC_SSH.nc
### TOP files for AGRIF
TRA1AGRIF=1_TRA_oil.nc

echo "Files retrieved for nest number 1"
fi

# Control parameter
MAXSUB=500 ## 55+58-d 7.5-8.31  # times to submit job based on lines of ${CONFIG}-${CASE}.db

date

for i in {1..100}
do
  echo "Running data assimilation: $i cycle..."
   . ~/RUN_TOOLS/nemo_jasper_v3.4_interannual_expt1.ksh
done

####. ~/RUN_TOOLS/nemo_jasper_v3.4_interannual_expt1.ksh

#cp solver.stat $P_CTL_DIR/solver.stat
