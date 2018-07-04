## -------------------------------------------------------------------------- ##
####### UNDER THIS LINE, YOU DON'T HAVE TO CHANGE ANYTHING #####################
######################################################################################
#    KSH script functions used below:
######################################################################################
# rapatrie is a shell function which tries to copy $1 on the local dir with the name $4
#         if the name is not defined or is none, it just skip
#         it then first tries to find the file on disk directory $2
#         if it fails it tries to mfget from $3 directory 
#         if it is not found anywhere, stop the script and issue a message

rapatrie()
{
 if [ $# -eq 3 ]; then
    tmpstr=$1
    if [ ${#tmpstr} -ne 0 ]; then
       if [ -f  $2/$1 ]; then
          ln -s  $2/$1 $3
       else
          echo $2/$1 not found anywhere ; exit;
       fi
    fi
 fi
}

expatrie()
{
 if [ -f $1 ]; then
    \cp  $1 $2/$3
 else
    echo "$1 not found"
 fi
}


# expatrie_res doas a mfput of file $1 on the directory $2, with filename $3
expatrie_res() 
{ 
   if [ -f $1 ]; then
      cp $1 $2/$3
   else
      echo "$1 is not found!"
   fi
}

# remove old restart files from the working directory
clean_res() { \rm  $P_R_DIR/*.$1.tar.* ; }

# check existence and eventually create directory
chkdir() { if [ ! -d $1 ] ; then mkdir $1 ; fi ; }

# LookInNamelist returns the value of a variable in the namelist
#         example: aht0=$(LookInNamelist aht0 )
LookInNamelist() { eval grep -e '$1\ ' namelist | grep -v -e '^\!' |awk '{printf "%d" , $3}' ; }

# Give the number of file containing $1 in its name
number_of_file() { ls -1 *$1* 2> /dev/null | wc -l  ; }

# get information from ice_in (xhu @UofA)
getVal(){
 #grep "$1.*=" $2 | grep -v -e '^\!' | awk -F\= '{print $2}' | awk '{print $1}' | sed -e "s/^'//" | rev | sed -e "s/^'//" | rev | sed -e 's/^\.//' -e 's/\.$//'
 grep -E "^[[:space:]]{0,}$1[[:space:]]{0,}=" $2 | awk -F\= '{print $2}' | awk '{print $1}' | sed -e "s/^'//" | rev | sed -e "s/^'//" | rev | sed -e 's/^\.//' -e 's/\.$//'
}

# Generate inter-annual forcing file name
GetForceName(){
  if [ $# -eq 2 ]; then
     echo ${1%.*}_y${2}.nc
  fi
}

source /global/software/modules/Modules/default/init/ksh

######################################################################################
## check existence of directories. Create them if they don't exist
set +x
chkdir $P_I_DIR
chkdir $P_R_DIR
chkdir $P_S_DIR
chkdir $TMPDIR

## (1) get all the working tools on the tmpdir directory
## -----------------------------------------------------
cd $TMPDIR
I_MPI_DEBUG=5

cat << eof > EMPave_old.dat
0
eof

## clean eventual (?) old files
[ -e OK ] && rm -f OK
[ -e islands.nc ] && rm -f islands.nc
\rm -f damping*

## waytmp : file which contain the way to tmp directory where the file run
pwd > waytmp
\cp waytmp $P_CTL_DIR/.

## copy of system and script tools
\cp $P_UTL_DIR/datfinyyyy .
\cp $P_UTL_DIR/DIMGproc_nnn/build_nc_mpp .
\cp $P_UTL_DIR/DIMGproc_nnn/build_nc .
\cp $P_UTL_DIR/MESH-MASK/build_nc_mesh_mask .

## copy the executable OPA
if [ -f $EXEC ]; then
  \cp $EXEC ./opa
else
  echo " OPA must me recompiled. Deleted from workdir"
  exit 1
fi

## copy of the control files ( .db and and template namelist )
\cp $P_CTL_DIR/namelist.${CONFIG_CASE} namelist
\cp $P_CTL_DIR/namelist_ice_lim2 namelist_ice
#\cp $P_CTL_DIR/namelist_ice_lim3 namelist_ice
\cp $P_CTL_DIR/namelistio namelistio
\cp $P_CTL_DIR/$CONFIG_CASE.db .
#\cp $P_CTL_DIR/xmlio_server.def .
#\cp $P_CTL_DIR/iodef.xml .
#\cp $P_CTL_DIR/iodef_ar5.xml .

## Using tracers, get tracer namelist
TOP=${TOP:-0}
if [ $TOP = 1 ] ; then
  \cp $P_CTL_DIR/namelist_top .  
fi

## Using AGRIF, get agrif namelists
AGRIF=${AGRIF:-0}
if [ $AGRIF = 1 ]; then
   NEST=${NEST:-1}
   \cp $P_CTL_DIR/1_namelist.${CONFIG_CASE} 1_namelist
   \cp $P_CTL_DIR/1_namelist.${CONFIG_CASE} 1_namelist1
   \cp $P_CTL_DIR/1_namelist_ice_lim2 1_namelist_ice
   \cp $P_CTL_DIR/1_namelistio 1_namelistio
   \cp $P_CTL_DIR/1_${CONFIG_CASE}.db 1_${CONFIG_CASE}.db
   \cp $P_CTL_DIR/AGRIF_FixedGrids.in AGRIF_FixedGrids.in
   echo "Copied nested namelist and configuration settings for nested domain "

  if [ $NEST = 2 ] ; then
   \cp $P_CTL_DIR/2_namelist.${CONFIG_CASE} 2_namelist
   \cp $P_CTL_DIR/2_namelist.${CONFIG_CASE} 2_namelist2
   \cp $P_CTL_DIR/2_namelist_ice_lim2 2_namelist_ice
   \cp $P_CTL_DIR/2_namelistio 2_namelistio
   \cp $P_CTL_DIR/2_${CONFIG_CASE}.db 2_${CONFIG_CASE}.db
  fi
fi

## (2) Set up the namelist for this run
## -------------------------------------
## exchange wildcards with the correc info from db
no=`tail -1 $CONFIG_CASE.db | awk '{print $1}' `
nit000=`tail -1 $CONFIG_CASE.db | awk '{print $2}' `
nitend=`tail -1 $CONFIG_CASE.db | awk '{print $3}' `

sed -e "s/NUMERO_DE_RUN/$no/" \
    -e "s/NIT000/$nit000/" \
    -e "s/NITEND/$nitend/"  namelist > namelist1
\cp namelist1 namelist

### Using agrif, put in proper job number, start and end time
if [ $AGRIF = 1 ]; then
   no1=`tail -1 1_$CONFIG_CASE.db | awk '{print $1}' `
   nit0001=`tail -1 1_$CONFIG_CASE.db | awk '{print $2}' `
   nitend1=`tail -1 1_$CONFIG_CASE.db | awk '{print $3}' `
   sed -e "s/NUMERO_DE_RUN/${no1}/" \
   -e "s/NIT000/${nit0001}/" \
   -e "s/NITEND/${nitend1}/"  1_namelist > 1_namelist1
   \cp 1_namelist1 1_namelist
   echo "Editing Conf-Case.db files for nested domain"

  if [ $NEST = 2 ] ; then
   no2=`tail -1 2_$CONFIG_CASE.db | awk '{print $1}' `
   nit0002=`tail -1 2_$CONFIG_CASE.db | awk '{print $2}' `
   nitend2=`tail -1 2_$CONFIG_CASE.db | awk '{print $3}' `
   sed -e "s/NUMERO_DE_RUN/${no2}/" \
   -e "s/NIT000/${nit0002}/" \
   -e "s/NITEND/${nitend2}/"  2_namelist > 2_namelist1
   \cp 2_namelist1 2_namelist
   echo "Editing Conf-Case.db files for nested domain number 2"
  fi

fi


## check restart case
if [ $no != 1 ] ; then
   sed -e "s/RESTART/true/" -e 's/RSTCTL/2/' namelist > namelist1
else 
   sed -e "s/RESTART/false/" -e 's/RSTCTL/1/' namelist > namelist1
fi
\cp namelist1 namelist

## check that the run period is a multiple of the dump period 
rdt=$(LookInNamelist rn_rdt)
nwri=$(LookInNamelist nn_write)

var=` echo 1 | awk "{ a=$nitend ; b=$nit000 ; c=$nwri ; nenr=(a-b+1)/c ; print nenr}"`
vernenr=` echo 1 | awk "{ a=$var; c=int(a); print c}"`

if [ $vernenr -ne  $var ] ; then
   echo 'WARNING: the run length is not a multiple of the dump period ...'
fi

## place holder for time manager (eventually)
if [ $no != 1 ] ; then
   ndatelast=`tail -2 $CONFIG_CASE.db | head -1 | awk '{print $4}' `
   nyearlast=`echo $ndatelast | awk '{print int($1 / 10000)}'`
   nyearcurrent=${nyearlast}
   isRST=1
else
  ndatelast=`grep -e '\ \ nn_date0\ ' namelist | grep -v -e '^\!' | awk '{printf "%d", $3}'`
  if [ ${#ndatelast} -eq 0 ]; then
     ndatelast=`grep -e '\ \ ndate0\ ' namelist | grep -v -e '^\!' | awk '{printf "%d", $3}'`
  fi
  nyearcurrent=`echo ${ndatelast} | awk '{printf "%d", $1/10000}'`
  nyearlast=${nyearcurrent}
  isRST=0
fi
nmonlast=`echo $ndatelast | awk '{a=$1;print a%10000}' | awk '{b=$1; print int(b/100)}'`
ndaylast=`echo $ndatelast | awk '{a=$1;print a%10000}' | awk '{b=$1; print b%100}'`
if [ $nmonlast -eq 1 -a ${ndaylast} -le 15 ]; then
   # need files from previoust year
   nyearlast=`expr $nyearlast - 1`
fi 
if [ ${nmonlast} -eq 12 -a ${ndaylast} -gt 15 ]; then
   # here might be a bug
   nyearcurrent=`expr $nyearcurrent + 1`
fi
if [ $nyearlast -lt 0 ]; then
   nyearlast=0
fi

ndays=` echo 1 | awk "{ a=int( ($nitend - $nit000 +1)*$rdt /86400.) ; print a }" `
ndateend=`./datfinyyyy $ndatelast $ndays`
nyearend=`echo $ndateend | awk '{print int($1/10000)}'`
echo "$ndays days to run, starting $ndatelast and stop on $nyearend"
nmonend=`echo $ndateend | awk '{a=$1; b=a%10000; print int(b/100)}'`
ndayend=`echo $ndateend | awk '{a=$1; b=a%10000; print b%100}'`
if [ $nmonend -eq 12 -a ${ndayend} -ge 15 ]; then
   nyearend=`expr $nyearend + 1`
fi

## (3) Look for input files
## ------------------------

## [3.1] : configuration files
## ==========================
## bathymetry
if [ $BAT = 1 ] ; then rapatrie $BATFILE_METER $P_I_DIR $OPA_BATFILE_METER ; fi

isZPS=`grep ln_zps namelist | awk -F\= '{print $2}' | awk '{print toupper($1)}' | sed -e 's/\.//g'`
if [ $isZPS = "TRUE" ] ; then
   echo "no level file needed for partial-step"
else
   rapatrie $BATFILE_LEVEL $P_I_DIR $OPA_BATFILE_LEVEL
fi


################################################################################
############# AGRIF BLOCK                       ################################
############# GETS AGRIF FILES FOR YOUR NEST    ################################
################################################################################
if [ $AGRIF = 1 ]; then
   echo "Your simulation is using AGRIF designation, so we will go gather AGRIF nesting files."
   #### Get Glorys 3d fields
   if [ $TSUVINI = 1 ]; then
      ln -fs $P_AGRIF_DIR/$INITT1 $OPA_INITT1
      ln -fs $P_AGRIF_DIR/$INITS1 $OPA_INITS1
      ln -fs $P_AGRIF_DIR/$INITU1 $OPA_INITU1
      ln -fs $P_AGRIF_DIR/$INITV1 $OPA_INITV1
      ln -fs $P_AGRIF_DIR/$INITSSH1 $OPA_INITSSH1
      if [ $NEST = 2 ]; then
         ln -fs $P_AGRIF_DIR/$INITT2 $OPA_INITT2
         ln -fs $P_AGRIF_DIR/$INITS2 $OPA_INITS2
         ln -fs $P_AGRIF_DIR/$INITU2 $OPA_INITU2
         ln -fs $P_AGRIF_DIR/$INITV2 $OPA_INITV2
         ln -fs $P_AGRIF_DIR/$INITSSH2 $OPA_INITSSH2
      fi
   fi
   # Get files for the first nest
   [ ${isZPS} != "TRUE" ] && rapatrie $BATFILE_LEVEL1 $P_AGRIF_DIR $OPA_BATFILE_LEVEL1
   rapatrie $BATFILE_METER1 $P_AGRIF_DIR $OPA_BATFILE_METER1
   rapatrie $COORDINATES1 $P_AGRIF_DIR $OPA_COORDINATES1
   rapatrie $TEMPDTA1 $P_AGRIF_DIR $OPA_TEMPDTA1
   rapatrie $SALDTA1 $P_AGRIF_DIR $OPA_SALDTA1
   rapatrie $ICEINI1 $P_AGRIF_DIR $OPA_ICEINI1
   #rapatrie $ICEDMP1 $P_AGRIF_DIR $OPA_ICEDMP1
   #rapatrie $TAUX_CORE1 $P_AGRIF_DIR $OPA_TAUX_CORE1
   #rapatrie $TAUY_CORE1 $P_AGRIF_DIR $OPA_TAUY_CORE1
   #rapatrie $TAIR_CORE1 $P_AGRIF_DIR $OPA_TAIR_CORE1
   #rapatrie $PRECIP_CORE1 $P_AGRIF_DIR $OPA_PRECIP_CORE1
   #rapatrie $HUMIDITY_CORE1 $P_AGRIF_DIR $OPA_HUMIDITY_CORE1
   #rapatrie $SHORT_WAVE_CORE1 $P_AGRIF_DIR $OPA_SHORT_WAVE_CORE1
   #rapatrie $LONG_WAVE_CORE1 $P_AGRIF_DIR $OPA_LONG_WAVE_CORE1
   #rapatrie $SNOW_CORE1 $P_AGRIF_DIR $OPA_SNOW_CORE1
   rapatrie $RUNOFF1 $P_AGRIF_DIR $OPA_RUNOFF1
   rapatrie $SSSDTA1 $P_AGRIF_DIR $OPA_SSSDTA1
   rapatrie $AGRIF_WEIGHT $P_AGRIF_DIR $OPA_FLXWEIGHT1
   rapatrie $AGRIF_WEIGHT $P_AGRIF_DIR 1_$OPA_FLXWEIGHT1
   #WEIGHT1=${WEIGHT1:-0}
   #RUNOFFWEIGHT1=${RUNOFFWEIGHT1:-""}
   #FLXWEIGHT1=${FLXWEIGHT1:-""}
   #if [ $WEIGHT1 = 1 ]; then
   #   [ -e $P_I_DIR/$FLXWEIGHT1 ] && rapatrie "$FLXWEIGHT1" $P_AGRIF_DIR $P_I_DIR $OPA_FLXWEIGHT1
   #   rapatrie "$FLXWEIGHT1" $P_AGRIF_DIR $P_I_DIR $AGRIFFLX
   #   [ -e $P_I_DIR${SubCORE}/$FLXWEIGHT1 ] && rapatrie "$FLXWEIGHT1" $P_I_DIR${SubCORE} $OPA_FLXWEIGHT1
   #   if [ ${#FLXWEIGHT2} -ne 0 ]; then
   #      [ -e $P_I_DIR/$FLXWEIGHT2 ] && rapatrie "$FLXWEIGHT2" $P_I_DIR $OPA_FLXWEIGHT2
   #      [ -e $P_I_DIR/${SubCORE}/$FLXWEIGHT2 ] && rapatrie "${FLXWEIGHT2}" $P_I_DIR${SubCORE} ${OPA_FLXWEIGHT2}
   #   fi
   #   if [ ${#RUNOFFWEIGHT1} -ne 0 ]; then
   #      if [ -e $P_I_DIR${SubRIVER}/$RUNOFFWEIGHT1 ]; then
   #      rapatrie "$RUNOFFWEIGHT1" $P_I_DIR${SubRIVER} $OPA_RUNOFFWEIGHT1
   #      else
   #      rapatrie "$RUNOFFWEIGHT1" $P_I_DIR $OPA_RUNOFFWEIGHT1
   #      fi
   #   fi
   #fi
   if [ $NEST = 2 ]; then
      rapatrie $RUNOFF2 $P_AGRIF_DIR $OPA_RUNOFF2
      rapatrie $SSSDTA2 $P_AGRIF_DIR $OPA_SSSDTA2
      rapatrie $AGRIF_WEIGHT2 $P_AGRIF_DIR $OPA_FLXWEIGHT2
      rapatrie $AGRIF_WEIGHT2 $P_AGRIF_DIR 2_$OPA_FLXWEIGHT2
      rapatrie $AGRIF_WEIGHT22 $P_AGRIF_DIR $OPA_FLXWEIGHT22
      rapatrie $BATFILE_METER2 $P_AGRIF_DIR $OPA_BATFILE_METER2
      rapatrie $COORDINATES2 $P_AGRIF_DIR $OPA_COORDINATES2
      rapatrie $TEMPDTA2 $P_AGRIF_DIR $OPA_TEMPDTA2
      rapatrie $SALDTA2 $P_AGRIF_DIR $OPA_SALDTA2
      rapatrie $ICEINI2 $P_AGRIF_DIR $OPA_ICEINI2
      echo "AGRIF nesting files retrieved for first nest."
   fi
fi

## coordinates
gr=${gr:-1}
if [ $gr = 1 ] ; then  rapatrie $COORDINATES $P_I_DIR $OPA_COORDINATES; fi

## relaxation coefficient file
REL=${REL:-0}
if [ $REL = 1 ] ; then  rapatrie $RELAX $P_I_DIR $OPA_RELAX ; fi

## bottom friction file
bfr=${bfr:-0}
if [ $bfr = 1 ] ; then  rapatrie $BFR $P_I_DIR $OPA_BFR;   fi

## geothermal heating
geo=${geo:-0}
if [ $geo = 1 ] ; then  rapatrie $GEO $P_I_DIR $OPA_GEO;   fi

## coeff 2d for ldfdyn
COEF2D=${COEF2D:-0}
if [ $COEF2D  = 1 ] ; then  rapatrie $AHM2D  $P_I_DIR $OPA_AHM2D; fi

## [3.2] : Initial conditions
## ============================
# TS initialization
if [ ${isRST} -eq 1 ]; then
   isTSInit="FALSE"
else
   isTSInit=`getVal ln_tsd_init namelist | awk '{print toupper($1)}'`
fi
SubTS=${SubTS:-"/TS"}
if [ ${isTSInit} = "TRUE" ]; then
   # temperature
   tempfile=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   [ ${#tempfile} -ne 0 ] && OPA_TEMPDTA=${tempfile%.*}.nc
   isInitTCL=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
   if [ ${isInitTCL} = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
         nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
         tmpfilemodel=${OPA_TEMPDTA%.*}_y${nyearmodel}.nc
         tmpfile=${TEMPDTA%.*}_y${nyearmodel}.nc
         # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
         rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $TEMPDTA $P_I_DIR${SubTS} $OPA_TEMPDTA
      rapatrie $TEMPDTA ${SubTS} $OPA_TEMPDTA
   fi 
   # salinity
   tempfile=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   [ ${#tempfile} -ne 0 ] && OPA_SALDTA=${tempfile%.*}.nc
   isInitSCL=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
   if [ ${isInitSCL} = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
         nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
         tmpfilemodel=${OPA_SALDTA%.*}_y${nyearmodel}.nc
         tmpfile=${SALDTA%.*}_y${nyearmodel}.nc
         # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
         rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $SALDTA $P_I_DIR${SubTS} $OPA_SALDTA
      rapatrie $SALDTA ${SubTS} $OPA_SALDTA
   fi
   echo "done  TS init"
fi

### AGRIF temp and salinity files
if [ $AGRIF = 1 ] ; then
   isTSInit1=`getVal ln_tsd_init 1_namelist | awk '{print toupper($1)}'`
   if [ ${isTSInit1} = "TRUE" ]; then
      # temperature
      tempfile1=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" 1_namelist | awk -F\' '{print $2}'`
      [ ${#tempfile1} -ne 0 ] && OPA_TEMPDTA1=1_${tempfile1%.*}.nc
      isInitTCL1=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" 1_namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
      if [ ${isInitTCL1} = FALSE ]; then
         for NY in `seq ${nyearlast} ${nyearend}`
         do
            nyearmodel1=`echo ${NY} | awk '{printf "%04d",$1}'`
            tmpfilemodel1=${OPA_TEMPDTA1%.*}_y${nyearmodel1}.nc
            tmpfile1=${TEMPDTA1%.*}_y${nyearmodel1}.nc
            rapatrie $tmpfile1 $P_AGRIF_DIR $tmpfilemodel1
         done
      else
         rapatrie $TEMPDTA1 $P_AGRIF_DIR $OPA_TEMPDTA1
      fi
      # salinity
      tempfile1=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" 1_namelist | awk -F\' '{print $2}'`
      [ ${#tempfile1} -ne 0 ] && OPA_SALDTA1=1_${tempfile1%.*}.nc
      isInitSCL1=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" 1_namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
      if [ ${isInitSCL1} = FALSE ]; then
         for NY in `seq ${nyearlast} ${nyearend}`
         do
            nyearmodel1=`echo ${NY} | awk '{printf "%04d",$1}'`
            tmpfilemodel1=${OPA_SALDTA1%.*}_y${nyearmodel1}.nc
            tmpfile1=${SALDTA1%.*}_y${nyearmodel1}.nc
            rapatrie $tmpfile1 $P_AGRIF_DIR $tmpfilemodel1
         done
      else
         rapatrie $SALDTA1 $P_AGRIF_DIR $OPA_SALDTA1
      fi
      echo "done  TS init"
   fi

   if [ $NEST = 2 ] ; then
      isTSInit2=`getVal ln_tsd_init 2_namelist | awk '{print toupper($1)}'`
      if [ ${isTSInit2} = "TRUE" ]; then
       # temperature
       tempfile2=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" 2_namelist | awk -F\' '{print $2}'`
       [ ${#tempfile2} -ne 0 ] && OPA_TEMPDTA2=2_${tempfile2%.*}.nc
       isInitTCL2=`grep -E "^[[:space:]]{0,}sn_tem_ini[[:space:]]{0,}=" 2_namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
       if [ ${isInitTCL2} = FALSE ]; then
          for NY in `seq ${nyearlast} ${nyearend}`
          do
             nyearmodel2=`echo ${NY} | awk '{printf "%04d",$1}'`
             tmpfilemodel2=${OPA_TEMPDTA2%.*}_y${nyearmodel2}.nc
             tmpfile2=${TEMPDTA2%.*}_y${nyearmodel2}.nc
             rapatrie $tmpfile2 $P_AGRIF_DIR $tmpfilemodel2
          done
       else
          rapatrie $TEMPDTA2 $P_AGRIF_DIR $OPA_TEMPDTA2
       fi
       # salinity
       tempfile2=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" 2_namelist | awk -F\' '{print $2}'`
       [ ${#tempfile2} -ne 0 ] && OPA_SALDTA2=2_${tempfile2%.*}.nc
       isInitSCL2=`grep -E "^[[:space:]]{0,}sn_sal_ini[[:space:]]{0,}=" 2_namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
       if [ ${isInitSCL2} = FALSE ]; then
          for NY in `seq ${nyearlast} ${nyearend}`
          do
             nyearmodel2=`echo ${NY} | awk '{printf "%04d",$1}'`
             tmpfilemodel2=${OPA_SALDTA2%.*}_y${nyearmodel2}.nc
             tmpfile2=${SALDTA2%.*}_y${nyearmodel2}.nc
             rapatrie $tmpfile2 $P_AGRIF_DIR $tmpfilemodel2
          done
       else
          rapatrie $SALDTA2 $P_AGRIF_DIR $OPA_SALDTA2
       fi
       echo "done  TS init for NEST 2"
    fi
   
   fi
fi

# ts damping
isTSDamp=`getVal ln_tsd_tradmp namelist | awk '{print toupper($1)}'`
if [ $isTSDamp = TRUE ]; then
   # temperature
   TEMPDTADMP=${TEMPDTADMP:-${TEMPDTA}}
   tempfile=`grep -E "^[[:space:]]{0,}sn_tem_dmp[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   [ ${#tempfile} -ne 0 ] && OPA_TEMPDTADMP=${tempfile%.*}.nc
   OPA_TEMPDTADMP=${OPA_TEMPDTADMP:-${OPA_TEMPDTA}}
   isDMPTCL=`grep -E "^[[:space:]]{0,}sn_tem_dmp[[:space:]]{0,}=" namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
   if [ ${isDMPTCL} = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
         nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
         tmpfilemodel=${OPA_TEMPDTADMP%.*}_y${nyearmodel}.nc
         tmpfile=${TEMPDTADMP%.*}_y${nyearmodel}.nc
         # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
         rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $TEMPDTADMP $P_I_DIR${SubTS} $OPA_TEMPDTADMP
      rapatrie $TEMPDTADMP ${SubTS} $OPA_TEMPDTADMP
   fi
   # salinity
   SALDTADMP=${SALDTADMP:-${SALDTA}}
   tempfile=`grep -E "^[[:space:]]{0,}sn_sal_dmp[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   [ ${#tempfile} -ne 0 ] && OPA_SALDTADMP=${tempfile%.*}.nc
   OPA_SALDTADMP=${OPA_SALDTADMP:-${OPA_SALDTA}}
   isDMPSCL=`grep -E "^[[:space:]]{0,}sn_sal_dmp[[:space:]]{0,}=" namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
   if [ ${isDMPSCL} = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
         nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
         tmpfilemodel=${OPA_SALDTADMP%.*}_y${nyearmodel}.nc
         tmpfile=${SALDTADMP%.*}_y${nyearmodel}.nc
         # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
         rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $SALDTADMP $P_I_DIR${SubTS} $OPA_SALDTADMP
      rapatrie $SALDTADMP ${SubTS} $OPA_SALDTADMP
   fi
   echo "done TS damp"
fi

## initial tsuv, might be not used in the future
TSUVINI=${TSUVINI:-0}
if [ $TSUVINI = 1 ]; then
   ln -fs $P_I_DIR/$INITT $OPA_INITT
   ln -fs $P_I_DIR/$INITS $OPA_INITS
   ln -fs $P_I_DIR/$INITU $OPA_INITU
   ln -fs $P_I_DIR/$INITV $OPA_INITV
   ln -fs $P_I_DIR/$INITSSH $OPA_INITSSH
fi

## mooring position
MOOR=${MOOR:-0}
if [ $MOOR = 1 ] ; then
   rapatrie init_mooring.$CONFIG $P_I_DIR  position.moor
fi

## Float initial position and restart float
IFLOAT=${IFLOAT:-0}
if [ $IFLOAT = 1 ] ;  then
   rapatrie $FLOATFIL $P_I_DIR  init_float
fi

## Ice initial condition only if no = 1
isICEinit=`getVal ln_limini namelist_ice | awk '{print toupper($1)}'`
if [ ${isICEinit} = TRUE ]; then
   ICE_INI=1
else
   ICE_INI=0
fi
if [ $ICE_INI = 1 -a $no -eq 1 ] ; then
   rapatrie $ICEINI  $P_I_DIR Ice_initialization.nc
fi

## Ice damping
isICEdmp=`getVal ln_limdmp namelist_ice | awk '{print toupper($1)}'`
if [ ${isICEdmp} = TRUE ]; then
   ICE_DMP=1
else
   ICE_DMP=0
fi
if [ $ICE_DMP = 1 ] ; then
   rapatrie $ICEDMP  $P_I_DIR $OPA_ICEDMP
fi

## CHLA
isQSR=`getVal ln_traqsr namelist | awk '{print toupper($1)}'`
if [ ${isQSR} = "TRUE" ]; then
   # Red-Green-Blue light penetration
   isRGB=`grep -E "^[[:space:]]{0,}ln_qsr_rgb[[:space:]]{0,}=" namelist | awk -F. '{print toupper($2)}'`
   if [ ${#isRGB} -ne 0 ]; then
      if [ $isRGB = "TRUE" ]; then
         ln -fs $P_I_DIR/$KRGB $OPA_KRGB
      fi
   fi
   isCHLData=`getVal nn_chldta namelist`
   if [ $isCHLData = 1 ]; then
      tmpfile=`grep -E "^[[:space:]]{0,}sn_chl[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
      OPA_CHLA=${tmpfile%.*}.nc
      isCHLACL=`grep -E "^[[:space:]]{0,}sn_chl[[:space:]]{0,}=" namelist | awk -F\, '{print toupper($5)}' | sed -e 's/\.//g'`
      if [ ${isCHLACL} = "TRUE" ]; then
         rapatrie "$CHLAFILE" $P_I_DIR $OPA_CHLA
      else
         echo "need inter-annual chlorophyl data, not ready yet. EXIT"
         exit
      fi
   fi
fi

## TRACER
if [ $TOP = 1 ]; then
   # tracer mask
   isMyTRCMask=${isMyTRCMask:-0}
   OPA_TRACERMASK=${OPA_TRACERMASK:-"mytracermask.nc"}
   if [ ${isMyTRCMask} -eq 1 ]; then
     rapatrie ${MyTracerMask} $P_I_DIR mytracermask.nc
   fi
   # trcdta
   isTRCDTA=`getVal ln_trcdta namelist_top | awk '{print toupper($1)}'`
   if [ ${isTRCDTA} = "TRUE" ]; then
      numTra=`grep -E "^[[:space:]]{0,}sn_trcdta[[:space:]]{0,}\(" namelist_top | wc -l`
      for ntr in `seq 1 ${numTra}`
      do
          ind=`expr ${ntr} - 1`
          eval TRA${ntr}='${TRA'${ntr}':-""}'
          eval cTRA='${TRA'${ntr}'}'
          tTRA=`grep -E "^[[:space:]]{0,}sn_trcdta[[:space:]]{0,}\(${ntr}\)[[:space:]]{0,}=" namelist_top | awk -F\' '{print $2}'`
          rapatrie ${cTRA} ${P_I_DIR}/${SubTRC} ${tTRA}.nc
      done
   fi


   TracerName=`grep "tracer(" namelist_top | sed -e 's/\ //g' | grep "^tracer" | awk -F\' '{print $2}'`
   TracerInit=`grep "tracer(" namelist_top | sed -e 's/\ //g' | grep "^tracer" | awk -F\, '{print toupper($4)}' | sed -e 's/\.//g'`
   numTra=`echo ${TracerInit} | awk '{print NF}'`
   for ntr in `seq 1 ${numTra}`
   do
       eval isT=`echo ${TracerInit} | awk -v a=$ntr '{print $a}'`
       if [ ${isT} = TRUE ]; then
          ind=`expr ${ntr} - 1`
          eval TRA${ntr}='${TRA'${ntr}':-""}'
          eval cTRA='${TRA'${ntr}'}'
          eval tTra=`echo ${TracerName} | awk -v a=$ntr '{print $a}'`
          if [ ${#cTRA} -ne 0 ]; then
             rapatrie ${cTRA} ${P_I_DIR} ${tTra}.nc
          else
             echo "Need tracer initial file! TRA${ntr}" && exit
          fi
       fi
   done
   echo "done tracers"
fi

## [3.3] : Forcing fields
#  ======================
## fluxes or parameters for bulks formulae
if [ $FLXSET1 = 1 ] ; then
   rapatrie $TAUX_SET1 $P_I_DIR $OPA_TAUX_SET1
   rapatrie $TAUY_SET1 $P_I_DIR $OPA_TAUY_SET1
   rapatrie "$PRECIP_SET1" $P_I_DIR $OPA_PRECIP_SET1
   rapatrie "$LIM_SET1"    $P_I_DIR $OPA_LIM_SET1
   rapatrie "$TAIR_SET1"   $P_I_DIR $OPA_TAIR_SET1
   rapatrie "$WSPD_SET1"   $P_I_DIR $OPA_WSPD_SET1
   rapatrie "$RUNOFF" $P_I_DIR $OPA_RUNOFF
   rapatrie "$RUNOFFWEIGHT" $P_I_DIR $OPA_RUNOFFWEIGHT
fi

# runoff
SubRIVER=${SubRIVER:-""}
IsRunoff=`grep -E "^[[:space:]]{0,}ln_rnf[[:space:]]{0,}=" namelist | awk -F. '{print toupper($2)}'`
IsRunoffCLim="TRUE"
if [ $IsRunoff = "TRUE" ]; then
   IsRunoffCLim=`grep -E "^[[:space:]]{0,}sn_rnf[[:space:]]{0,}=" namelist | awk -F, '{print toupper($5)}' | sed -e 's/\.//g'`
   tmpfile=`grep -E "^[[:space:]]{0,}sn_rnf[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   OPA_RUNOFF=${tmpfile%.*}.nc
   #   if [ $AGRIF = 1 ]; then
   #   tmpfile1=`grep -E "^[[:space:]]{0,}sn_rnf[[:space:]]{0,}=" 1_namelist | awk -F\' '{print $2}'`
   #   OPA_RUNOFF1=${tmpfile1%.*}.nc
   #   echo "agrif runoff tempfile is ${tmpfile1}"
   #   fi
   echo "runoff tempfile is ${tmpfile}"
   if [ $IsRunoffCLim = "TRUE" ]; then
      if [ -e ${P_I_DIR}${SubRIVER}/$RUNOFF ]; then
         rapatrie "$RUNOFF" $P_I_DIR${SubRIVER} $OPA_RUNOFF
      else
         rapatrie "$RUNOFF" $P_I_DIR $OPA_RUNOFF    # CP 
         # if [ $AGRIF = 1 ]; then
         #    rapatrie $RUNOFF1 $P_AGRIF_DIR $OPA_RUNOFF1 
         # fi
      fi
   fi
   RiverMask=`grep -E "^[[:space:]]{0,}sn_cnf[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   if [ "${RiverMask%.*}.nc" = $OPA_RUNOFF ]; then
      echo "runoff and mask are in the same file"
   else
     if [ -e ${P_I_DIR}${SubRIVER}/$RUNOFF_mask ]; then
        rapatrie "$RUNOFF_mask" ${P_I_DIR}${SubRIVER} "${RiverMask%.*}.nc"
     else 
        rapatrie "$RUNOFF_mask" $P_I_DIR "${RiverMask%.*}.nc"
     fi
   fi
fi

## fluxes or parameters for bulks formulae
IsIA=${IsIA:-0};
SubCORE=${SubCORE:-""}
if [ $FLXCORE = 1 ] ; then
   if [ $IsIA = 0 ]; then
      rapatrie "$PRECIP_CORE" $P_I_DIR${SubCORE} $OPA_PRECIP_CORE
      rapatrie "$TAUX_CORE" $P_I_DIR${SubCORE} $OPA_TAUX_CORE
      rapatrie "$TAUY_CORE" $P_I_DIR${SubCORE} $OPA_TAUY_CORE
      rapatrie "$HUMIDITY_CORE" $P_I_DIR${SubCORE} $OPA_HUMIDITY_CORE
      rapatrie "$SHORT_WAVE_CORE" $P_I_DIR${SubCORE} $OPA_SHORT_WAVE_CORE
      rapatrie "$LONG_WAVE_CORE" $P_I_DIR${SubCORE} $OPA_LONG_WAVE_CORE
      rapatrie "$TAIR_CORE" $P_I_DIR${SubCORE} $OPA_TAIR_CORE
      rapatrie "$SNOW_CORE" $P_I_DIR${SubCORE} $OPA_SNOW_CORE
   else
      echo "LastYear is: $nyearlast"
      nyearthis=$(( $nyearlast + 1 ))
      echo "ThisYear is: $nyearthis"
      echo "EndYear is: $nyearend"
      for NY in `seq ${nyearlast} ${nyearend}`
      do
         nyearmodel=`echo $NY | awk '{printf "%04d", $1}'`
         nyearmodel=y${nyearmodel}
         tmpfile=`GetForceName $PRECIP_CORE $NY`
         tmpfilemodel=${OPA_PRECIP_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $TAUX_CORE $NY`
         tmpfilemodel=${OPA_TAUX_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $TAUY_CORE $NY`
         tmpfilemodel=${OPA_TAUY_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $HUMIDITY_CORE $NY`
         tmpfilemodel=${OPA_HUMIDITY_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $SHORT_WAVE_CORE $NY`
         tmpfilemodel=${OPA_SHORT_WAVE_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $LONG_WAVE_CORE $NY`
         tmpfilemodel=${OPA_LONG_WAVE_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $TAIR_CORE $NY`
         tmpfilemodel=${OPA_TAIR_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         tmpfile=`GetForceName $SNOW_CORE $NY`
         tmpfilemodel=${OPA_SNOW_CORE%.*}_${nyearmodel}.nc
         rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
         if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         if [ $IsRunoffCLim = "FALSE" ]; then
            tmpfile=`GetForceName $RUNOFF $NY`
            tmpfilemodel=${OPA_RUNOFF%.*}_${nyearmodel}.nc
            rapatrie $tmpfile $P_I_DIR${SubCORE} $tmpfilemodel
            if [ $AGRIF = 1 ] ; then rapatrie $tmpfile $P_I_DIR${SubCORE} 1_$tmpfilemodel ; fi
         fi
      done
   fi
   echo "done CORE forcings"
fi
WEIGHT=${WEIGHT:-0}
FLXWEIGHT2=${FLXWEIGHT2:-""}
RUNOFFWEIGHT=${RUNOFFWEIGHT:-""}
if [ $WEIGHT = 1 ]; then
   tmpfile=`sed -n '/^&namsbc_core/,/^&nam/p' namelist | grep -E "^[[:space:]]{0,}sn_wndi[[:space:]]{0,}=" | awk -F\, '{print $7}' | sed -e "s/'//g" | sed -e 's/\ //g'`
   if [ ${#tmpfile} -ne 0 ]; then
      OPA_FLXWEIGHT=${tmpfile}
   else
      tmpfile=`sed -n '/^&namsbc_core/,/^&nam/p' namelist | grep -E "^[[:space:]]{0,}sn_tair[[:space:]]{0,}=" | awk -F\, '{print $7}' | sed -e "s/'//g" | sed -e 's/\ //g'`
      [ ${#tmpfile} -ne 0 ] && OPA_FLXWEIGHT=${tmpfile}
   fi

   [ -e $P_I_DIR/$FLXWEIGHT ] && rapatrie "$FLXWEIGHT" $P_I_DIR $OPA_FLXWEIGHT
   [ -e $P_I_DIR${SubCORE}/$FLXWEIGHT ] && rapatrie "$FLXWEIGHT" $P_I_DIR${SubCORE} $OPA_FLXWEIGHT
   if [ ${#FLXWEIGHT2} -ne 0 ]; then
      [ -e $P_I_DIR/$FLXWEIGHT2 ] && rapatrie "$FLXWEIGHT2" $P_I_DIR $OPA_FLXWEIGHT2
      [ -e $P_I_DIR${SubCORE}/$FLXWEIGHT2 ] && rapatrie "${FLXWEIGHT2}" $P_I_DIR${SubCORE} ${OPA_FLXWEIGHT2}
   fi
   if [ ${#RUNOFFWEIGHT} -ne 0 ]; then
      if [ -e $P_I_DIR${SubRIVER}/$RUNOFFWEIGHT ]; then
         rapatrie "$RUNOFFWEIGHT" $P_I_DIR${SubRIVER} $OPA_RUNOFFWEIGHT
      elif [ -e $P_I_DIR/$RUNOFFWEIGHT ]; then
         rapatrie $RUNOFFWEIGHT $P_I_DIR $OPA_RUNOFFWEIGHT
      elif [ -e $P_I_DIR${SubCORE}/$RUNOFFWEIGHT ]; then
         echo "should see this line, to get the runoff weight file"
         rapatrie $RUNOFFWEIGHT $P_I_DIR${SubCORE} $OPA_RUNOFFWEIGHT
      else
         echo "runoff weight file is missing" && exit
      fi
   fi
   echo "done weight file(s)"
fi

## Open boundaries files
OBC=`getVal nn_obcdta namelist`
[ ${#OBC} -eq 0 ] && OBC=`getVal nobc_dta namelist`
[ ${#OBC} -eq 0 ] && OBC=0
if [ $OBC = 1 ] ;  then
   SubOBC=${SubOBC:-""}
   obcTypeList=(EAST NORTH WEST SOUTH)
   for cOBC in ${obcTypeList[*]}
   do
       cT=`echo ${cOBC} | cut -c1-1`
       cOBCLine=`grep -E "^[[:space:]]{0,}sn_obc${cT}[[:space:]]{0,}=" namelist`
       iscOBCExist=`echo ${cOBCLine} | awk -F\, '{print $1}' | awk -F\= '{print toupper($2)}' | sed -e 's/\.//g'`
       if [ ${iscOBCExist} = "TRUE" ]; then
          isCOBCCL=`echo ${cOBCLine} | awk -F\, '{print toupper($4)}' | sed -e 's/\.//g'`
          if [ ${isCOBCCL} = "FALSE" ]; then
             for NY in `seq ${nyearlast} ${nyearend}`
             do
                nyearmodel=`echo $NY | awk '{printf "%04d", $1}'`
                nyearmodel="y${nyearmodel}"
                # TS
                eval "infile=\${${cOBC}OBCTS}"
                tmpfile=`echo $infile | sed -e "s/y0000/${nyearmodel}/"`
                eval "outfile=\${OPA_${cOBC}OBCTS}"
                tmpfilemodel=`echo ${outfile} | sed -e "s/y0000/${nyearmodel}/"`
                eval "rapatrie $tmpfile $P_I_DIR${SubOBC} $tmpfilemodel"
                # U
                eval "infile=\${${cOBC}OBCU}"
                tmpfile=`echo $infile | sed -e "s/y0000/${nyearmodel}/"`
                eval "outfile=\${OPA_${cOBC}OBCU}"
                tmpfilemodel=`echo ${outfile} | sed -e "s/y0000/${nyearmodel}/"`
                eval "rapatrie $tmpfile $P_I_DIR${SubOBC} $tmpfilemodel"
                # V
                eval "infile=\${${cOBC}OBCV}"
                tmpfile=`echo $infile | sed -e "s/y0000/${nyearmodel}/"`
                eval "outfile=\${OPA_${cOBC}OBCV}"
                tmpfilemodel=`echo ${outfile} | sed -e "s/y0000/${nyearmodel}/"`
                eval "rapatrie $tmpfile $P_I_DIR${SubOBC} $tmpfilemodel"
             done
          else
             eval "infile=\${${cOBC}OBCTS}"
             eval "outfile=\${OPA_${cOBC}OBCTS}"
             eval "rapatrie ${infile} \$P_I_DIR${SubOBC} ${outfile}"
             eval "infile=\${${cOBC}OBCU}"
             eval "outfile=\${OPA_${cOBC}OBCU}"
             eval "rapatrie ${infile} \$P_I_DIR${SubOBC} ${outfile}"
             eval "infile=\${${cOBC}OBCV}"
             eval "outfile=\${OPA_${cOBC}OBCV}"
             eval "rapatrie ${infile} \$P_I_DIR${SubOBC} ${outfile}"
          fi
       fi
   done
   echo "done OBC(s)"
fi

## SST & SSS surfae restoring
SSS=${SSS:-0}
SST=${SST:-0}
isRESTORING=`getVal ln_ssr namelist | awk '{print toupper($1)}'`
## SSS files
isSSS=`getVal nn_sssr namelist`
[ ${isRESTORING} = "TRUE" -a $isSSS = 1 ] && SSS=1
[ ${isRESTORING} = "TRUE" -a $isSSS = 2 ] && SSS=1
if [ $SSS = 1 ] ; then
   # nom can be computed to fit the year we need ...
   tmpfile=`grep -E "^[[:space:]]{0,}sn_sss[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   isSSSCL=`grep -E "^[[:space:]]{0,}sn_sss[[:space:]]{0,}=" namelist | awk -F, '{print toupper($5)}' | sed -e 's/\.//g'`
   [ ${#tmpfile} -ne 0 ] && OPA_SSSDTA=${tmpfile}
   if [ $isSSSCL = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
          nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
          tmpfile=${SSSDTA%.*}_y${nyearmodel}.nc
          tmpfilemodel=${OPA_SSSDTA%.*}_y${nyearmodel}.nc
          # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
          rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $SSSDTA $P_I_DIR${SubTS} $OPA_SSSDTA
      rapatrie $SSSDTA ${SubTS} $OPA_SSSDTA
   fi
   echo "done SSS"
fi
## SST files
isSST=`getVal nn_sstr namelist`
[ ${isRESTORING} = "TRUE" -a ${isSST} = 1 ] && SST=1
if [ $SST = 1 ] ; then
   # nom can be computed to fit the year we need ...
   tmpfile=`grep -E "^[[:space:]]{0,}sn_sst[[:space:]]{0,}=" namelist | awk -F\' '{print $2}'`
   isSSSCL=`grep -E "^[[:space:]]{0,}sn_sst[[:space:]]{0,}=" namelist | awk -F, '{print toupper($5)}' | sed -e 's/\.//g'`
   [ ${#tmpfile} -ne 0 ] && OPA_SSTDTA=${tmpfile}
   if [ $isSSTCL = FALSE ]; then
      for NY in `seq ${nyearlast} ${nyearend}`
      do
          nyearmodel=`echo ${NY} | awk '{printf "%04d",$1}'`
          tmpfile=${SSTDTA%.*}_y${nyearmodel}.nc
          tmpfilemodel=${OPA_SSTDTA%.*}_y${nyearmodel}.nc
          # rapatrie $tmpfile $P_I_DIR${SubTS} $tmpfilemodel
          rapatrie $tmpfile ${SubTS} $tmpfilemodel
      done
   else
      # rapatrie $SSTDTA $P_I_DIR${SubTS} $OPA_SSTDTA
      rapatrie $SSTDTA ${SubTS} $OPA_SSTDTA
   fi
   echo "done SST"
fi

## Feed back term file (fbt)
FBT=${FBT:-0}
if [ $FBT = 1 ] ; then
   # nom can be computed to fit the year we need ...
   nom=$FBTDTA
   rapatrie $FBTDTA $P_I_DIR $nom
fi

## [3.4] : restart files
#  ======================
prev_ext=$(( $no - 1 ))      # file extension of previous run
prev_stpt=$(( $nit000 - 1 )) # file extension of previous run
prev_stp=`echo ${prev_stpt} | awk '{printf "%08d", $1}'`

if [ $AGRIF = 1 ] ; then
   prev_ext1=$(( $no1 - 1 ))      # file extension of previous run
   prev_stpt1=$(( $nit0001 - 1 )) # file extension of previous run
   prev_stp1=`echo ${prev_stpt1} | awk '{printf "%08d", $1}'`
   echo "prev_ext1, prev_stpt1 and prev_stp as follows"
   echo $prev_ext1
   echo $prev_stpt1
   echo $prev_stp1 
fi
date

## model restarts
isICE=`getVal nn_ice namelist`
[ ${isICE} -ge 2 ] && ICE=1
isKEYNETCDF=${isKEYNETCDF:-0}
if [ ${isKEYNETCDF} -eq 1 ]; then
   rstSTR="nc"
else
   rstSTR="dimg"
fi

if [ $no -eq  1 ] ; then
   # clear olds files in case on a brand new run ..
   rm -f $P_R_DIR/islands.nc
   rm -f islands.nc
else
   # ocean
   for rest in `ls $P_R_DIR/ | grep ${CONFIG_CASE}_ | grep ${prev_stp}_restart_0 | grep .${rstSTR}.${prev_ext}` ; do
       ln -fs ${P_R_DIR}/$rest $( echo $rest | sed -e "s/${CONFIG_CASE}_//" -e "s/${rstSTR}.${prev_ext}/${rstSTR}/" | cut -c10- )
   done
   if [ ${AGRIF} -eq 1 ]; then
      for rest in `ls $P_R_DIR/ | grep 1_${CONFIG_CASE}_ | grep ${prev_stp1}_restart_0 | grep .${rstSTR}.${prev_ext}` ; do
          ln -fs ${P_R_DIR}/$rest 1_$( echo $rest | sed -e "s/${CONFIG_CASE}_//" -e "s/${rstSTR}.${prev_ext}/${rstSTR}/" | cut -c12- )
      done
   fi
   # ice
   if [ $ICE = 1 ] ; then
      for rest in `ls $P_R_DIR/ | grep ${CONFIG_CASE}_ | grep ${prev_stp}_restart_ice_ | grep .${rstSTR}.${prev_ext}` ; do
          ln -fs ${P_R_DIR}/$rest  $( echo $rest | sed -e "s/${CONFIG_CASE}_//" -e 's/ice/ice_in/' -e "s/${rstSTR}.${prev_ext}/${rstSTR}/" | cut -c10- )
      done
   fi
   if [ ${AGRIF} -eq 1 ]; then
      for rest in `ls $P_R_DIR/ | grep 1_${CONFIG_CASE}_ | grep ${prev_stp1}_restart_ice_ | grep .${rstSTR}.${prev_ext}` ; do
          ln -fs ${P_R_DIR}/$rest  1_$( echo $rest | sed -e "s/${CONFIG_CASE}_//" -e 's/ice/ice_in/' -e "s/${rstSTR}.${prev_ext}/${rstSTR}/" | cut -c12- )
      done
   fi
   # OBC
   if [ $OBC = 1 ] ; then
      if [ -f ${P_R_DIR}/restart.obc.$prev_ext ]; then
         ln -fs $P_R_DIR/restart.obc.$prev_ext restart.obc
      else
         for rest in `ls $P_R_DIR/ | grep ${CONFIG_CASE}_ | grep ${prev_stp}_restart_obc.output` ; do
             ln -fs $P_R_DIR/$rest $( echo $rest | sed -e "s/${CONFIG_CASE}_//" -e "s/.${prev_ext}$//" -e 's/restart_obc/restart.obc/' | cut -c10- )
         done
      fi
   fi
   # TOP 
   if [ $TOP -eq 1 ]; then
      echo "Need restart files for top!!!"
   fi
fi

## Float initial position and restart float
if [ $RFLOAT = 1 -a  $IFLOAT = 1 ] ;  then
   rapatrie restart_float.$prev_ext $P_R_DIR  restart_float
fi

date
pwd

## (4) Run the code
## ----------------
echo "Starting run at: `date`"
module load library/netcdf/4.1.3
#module load library/szip/2.1
#module load library/openmpi/1.8.4-intel
mpirun --mca btl_openib_max_eager_rdma 0 --mca mpi_leave_pinned 0 --mca orte_tmpdir_base ${OMPI_TMPDIR} -np ${PBS_NP} ./opa
echo "Job finished at: `date`"
echo  $MP_PROCS

## (5) Post processing of the run
## ------------------------------

## [5.1] check the status of the run
#  ================================
# touch OK file if the run finished OK
isOK=`sed -n "/run stop at/,//p" ocean.output | grep AAAAAAAA`
isERROR=`sed -n "/run stop at/,//p" ocean.output | grep "E R R O R"`
if [ ${#isERROR} -eq 0 ]; then
   if [ ${#isOK} -ne 0 ]; then
      isOK=`echo $isOK | sed 's/A//g'`
      [ ${#isOK} -eq 0 ] && touch OK
   fi
fi

# gives the rights rx to go
chmod -R go+rx $TMPDIR

# The run crashed :( . Send back some infos on the CTL directory
if [ ! -f OK ] ; then
   ext='ABORT'
   \cp ocean.output $P_CTL_DIR/ocean.output.$$.$ext
   [ -e islands.stat ] && \cp islands.stat $P_CTL_DIR/islands.stat.$ext

   if [ ! -f time.step ] ; then
      echo "Script stop now after copy of the ctl-file in the CTL directory"
      echo "No time-step are made by OPA, we stop before"   
      exit
    fi 
fi 

## [5.2] Update the CONFIG_CASE.db file, if the run is OK
#  ======================================================
if [ -f OK ]  ; then
   # RAJOUT SEB
   cp ocean.output $P_CTL_DIR/ocean.output.$$.OK
   # FIN RAJOUT SEB
   DIR=``
   echo "Run OK"
   no=$(( $no + 1 ))
   if [ $AGRIF = 1 ] ; then
      no1=$(( $no1 + 1 ))
   fi

   # add last date at the current line
   nline=$(wc $CONFIG_CASE.db | awk '{print $1}')

   # aammdd is the ndastp of the last day of the run ...
   # where can we get it ???? : in the ocean.output for sure !!
   aammdd=$( tail -100 ocean.output | grep -e 'run stop at' | awk '{print $NF}' )

   ncol=$( tail -1 $CONFIG_CASE.db | awk '{print NF} ')
   if [ $ncol -eq  3 ] ; then
      # if the only three columns at the last line ==> add the stop date 
     last=`tail -1 $CONFIG_CASE.db | awk '{print $NF}'`
     sed -e "s/$last/$last\ $aammdd/" $CONFIG_CASE.db > tmpdb
     mv -f tmpdb $CONFIG_CASE.db
   else
     echo "${CONFIG_CASE}.db is already updated: ncol= $ncol"
   fi

   # add a new last line for the next run
   dif=$((  $nitend - $nit000  + 1  ))
   nit000=$(( $nitend + 1 ))
   nitend=$(( $nitend + $dif ))
   echo $no $nit000 $nitend >> $CONFIG_CASE.db

   cat $CONFIG_CASE.db
   \cp $CONFIG_CASE.db $P_CTL_DIR/
   if [ $AGRIF = 1 ] ; then
      dif1=$((  $nitend1 - $nit0001  + 1  ))
      nit0001=$(( $nitend1 + 1 ))
      nitend1=$(( $nitend1 + $dif1 ))
      echo $no1 $nit0001 $nitend1 >> 1_$CONFIG_CASE.db

      cat 1_$CONFIG_CASE.db
      \cp 1_$CONFIG_CASE.db $P_CTL_DIR/
      echo "$no1 $nit0001 $nitend1 "
      echo " above information should be put into 1_.db"
   fi
else
  # Run is !NOT! OK : create $P_S_DIR/ABORT directory
  DIR=/ABORT
  ext=abort
  if [ ! -d ${P_S_DIR}${DIR} ] ; then mkdir ${P_S_DIR}${DIR} ; fi
  if [ ! -d ${P_R_DIR}${DIR} ] ; then mkdir ${P_R_DIR}${DIR} ; fi
fi 

if [ -f OK ] ;  then
   ext=$(( $no - 1 ))
fi

## [5.2*] begin Data Assimilation cycle
#  =======================================================
~/DA_EXPT1/da_expt1.ksh

## [5.3] rename the restart files and send them to storage
#  =======================================================
if [ -f OK ] ; then
   echo "making restart files"

   ndigit=`ls ${CONFIG_CASE}_*_restart_*001.${rstSTR} | head -1 | awk -F\_ '{print $NF}' | awk -F\. '{print length($1)}'`
   cpustr=`printf "%${ndigit}s" | sed -e 's/\ /?/g'`
   # O C E A N 
   # *********
   for rest in `ls ${CONFIG_CASE}_*_restart_${cpustr}.${rstSTR}` ; do
      mv $rest $rest.$ext
      expatrie $rest.$ext $P_R_DIR
   done
   if [ ${AGRIF} -eq 1 ]; then
      for rest in `ls 1_${CONFIG_CASE}_*_restart_${cpustr}.${rstSTR}` ; do
          mv $rest $rest.$ext
          expatrie $rest.$ext $P_R_DIR
      done
   fi
   # I C E
   # *****
   if [ $ICE = 1 ] ; then
      for  rest in `ls ${CONFIG_CASE}_*_restart_ice_${cpustr}.${rstSTR}` ; do
         mv $rest $rest.$ext
         expatrie $rest.$ext $P_R_DIR
      done
   fi
   if [ ${AGRIF} -eq 1 ]; then
      for  rest in `ls 1_${CONFIG_CASE}_*_restart_ice_${cpustr}.${rstSTR}` ; do
           mv $rest $rest.$ext
           expatrie $rest.$ext $P_R_DIR
      done
   fi
   
   #  Open Boundary Conditions
   # **************************
   if [ $OBC = 1 ] ; then
      if [ -f restart.obc.output ]; then
         mv restart.obc.output restart.obc.$ext
         expatrie_res restart.obc.$ext $P_R_DIR
      else
        for  rest in  *restart_obc.output.* ; do
           mv $rest $rest.$ext
           expatrie_res $rest.$ext $P_R_DIR
        done
      fi
   fi
   # TOP
   if [ $TOP = 1 ]; then
      ndigittop=`ls ${CONFIG_CASE}_*_restart_trc_*001.${rstSTR} | head -1 | awk -F\_ '{print $NF}' | awk -F\. '{print length($1)}'`
      cpustrtop=`printf "%${ndigittop}s" | sed -e 's/\ /?/g'`
      for rest in `ls ${CONFIG_CASE}_*_restart_trc_${cpustrtop}.${rstSTR}` ; do
          mv $rest $rest.$ext
          expatrie_res $rest.$ext $P_R_DIR
      done
      if [ ${AGRIF} -eq 1 ]; then
         for rest in `ls 1_${CONFIG_CASE}_*_restart_trc_${cpustrtop}.${rstSTR}` ; do
             mv $rest $rest.$ext
             expatrie_res $rest.$ext $P_R_DIR
         done
      fi
   fi
fi
 
## [5.4] Ready to re-submit the job NOW (to take place in the queue)
# ==================================================================
#if [ -f OK ] ; then
#   TESTSUB=$( wc $CONFIG_CASE.db | awk '{print $1}' )
#   if [ $TESTSUB -le  $MAXSUB ] ; then
#      cd $P_CTL_DIR
#      ssh jasper "qsub /home/chako/RUN_ANHA4/ANHA4-EXPT1/CTL/$CONFIG_CASE.ksh"
#      cd $TMPDIR  # go back to tmpdir for the end of the run
#   else
#      echo Maximum auto re-submit reached.
#   fi
#fi 

## [5.5] send the Netcdf Files to storage
#  ==================================================
   
#for f in ${CONFIG_CASE}_*_grid[TUVW].nc  ${CONFIG_CASE}_*_icemod.nc ; do
#    expatrie $f $P_S_DIR $f
#done
 
#if [ $AGRIF = 1 ] ; then
#   for f in [123]_${CONFIG_CASE}_*_grid[TUVW].nc  [123]_${CONFIG_CASE}_*_icemod.nc ; do
#       expatrie $f $P_S_DIR $f
#   done
#   for f in Crop_${CONFIG_CASE}_*_grid[TUVW].nc Crop_${CONFIG_CASE}_*_icemod.nc ; do
#       expatrie $f $P_S_DIR $f
#   done
#fi

#nmsh=$(LookInNamelist nmsh)
#if [ nmsh = 1 ] ; then build_nc_nmsh ; fi

## [5.6]  Put annex files in tarfile and send to gaya
# ===================================================
barofile=""; islandfile=""; datefile=""
[ -f barotropic.stat ] &&  mv barotropic.stat barotropic.stat.$ext && barofile="barotropic.stat.$ext"
[ -f islands.stat    ] &&  mv islands.stat    islands.stat.$ext    && islandfile="islands.stat.$ext" 
mv ocean.output ocean.output.$ext
mv time.step time.step.$ext
[ -e date.file ] && mv date.file date.file.$ext && datefile="date.file.$ext"

tar cvf tarfile.${CONFIG_CASE}_annex.$ext  ${barofile} ${islandfile} ${datefile} \
        ocean.output.$ext time.step.$ext
chmod ugo+r  tarfile.${CONFIG_CASE}_annex.$ext
expatrie  tarfile.${CONFIG_CASE}_annex.$ext $P_S_DIR tarfile.${CONFIG_CASE}_annex.$ext

## [5.9] Mesmask files
# ====================
#if [ $MESH = 1 ] ; then
#   echo Building mesh_mask files
#   build_nc_mesh_mask 
#   \cp mesh*.nc mask*.nc  $P_R_DIR$DIR/.
#fi 

## [5.10] Miscelaneous
# ====================
#cp ocean.output.$ext $P_S_DIR/
#cp namelist ${P_S_DIR}/namelist_oce.$ext
#cp namelist_ice ${P_S_DIR}/namelist_ice.$ext

## copy over agrif output files to output folder
#if [ $AGRIF = 1 ] ; then
#   for f in 1 ; do
#       cp ${f}_ocean.output ${P_S_DIR}/${f}_ocean.output.$ext
#       cp ${f}_time.step ${P_S_DIR}/${f}_time.step.$ext
#       cp ${f}_namelist ${P_S_DIR}/${f}_namelist_oce.$ext
#       cp ${f}_namelist_ice ${P_S_DIR}/${f}_namelist_ice.$ext
#   done
#fi

##exit
## delete TMPDIR
# ==============
DELTEMP=${DELTEMP:-0}
if [ ${DELTEMP} -eq 1 ]; then
   n=$(number_of_file 2D )
   list=''
   n=0
   while [ $n -lt $NCPUS ]
   do
         n=$(( $n + 1 ))
         tmp=`echo $n | awk '{printf "%03d", $1 }'`
         list="  $list $tmp "
   done

   for f in   `echo $list`
   do
      \rm *_2D_*dimgproc.$f
      \rm *_ICEMOD_*dimgproc.$f
      \rm *_KZ_*dimgproc.$f
      \rm *_S_*dimgproc.$f
      \rm *_T_*dimgproc.$f 
      \rm *_U_*dimgproc.$f 
      \rm *_V_*dimgproc.$f
      \rm *_W_*dimgproc.$f
   done
   \rm *
fi
#########################################################################
##                                END                                  ##
########################################################################
