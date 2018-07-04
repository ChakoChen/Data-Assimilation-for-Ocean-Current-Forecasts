## (1) THIS FILE PROCESSES THE OUTPUT AND RESTART FILES
ifort -g -C -O3 -xHost -ipo -no-prec-div -mcmodel=medium -convert big_endian -lnetcdf -lnetcdff ~/POSTPROCESS/construct_DA_domain_from_restart.f90 -o DA_domain_restart.out

ifort -g -C -O3 -xHost -ipo -no-prec-div -mcmodel=medium -convert big_endian -lnetcdf -lnetcdff ~/POSTPROCESS/construct_DA_domain.f90 -o DA_domain.out

##ifort -g -C -O3 -xHost -ipo -no-prec-div -mcmodel=medium -convert big_endian -lnetcdf -lnetcdff ~/POSTPROCESS/construct_NEST_domain.f90 -o NEST_domain.out

ifort -g -C -O3 -xHost -ipo -no-prec-div -mcmodel=medium -convert big_endian -lnetcdf -lnetcdff ~/POSTPROCESS/update_restart.f90 -o update.out

## (2) COMBINE RESTART FILES FROM 48 PROCESSORS INTO ONE FILE (i.e. Background file) 
ls 1_ANHA4-*restart* > output_files
head -1 output_files > name_example
awk '{print length($0);}' name_example > name_length
./DA_domain_restart.out
##./NEST_domain.out
cp *background.dta ~/DA_EXPT1/output/SAVE
rm output_files name_example name_length

## (3) COPY BACKGROUND FILE FOR DA, AND RUN DA
cp *background.dta ~/DA_EXPT1/input/background.dta 
cd $TMPDIR

## (4.1) DA: compile file for writing time file for DA 
ifort -g -C -O3 -xHost -ipo -no-prec-div -mcmodel=medium -convert big_endian -lnetcdf -lnetcdff ~/DA_EXPT1/DA_time.f90 -o DA_time.out

## (4.2) DA: write the time file first according to output files, then do DA cycle
ls ANHA4*grid_T* > output_files
head -1 output_files > name_example
awk '{print length($0);}' name_example > name_length

./DA_time.out
mv DA_time.txt ~/DA_EXPT1/
rm output_files name_example name_length
echo "Time file is written for DA."

## (4.3) DA: compile DA and run
make -C ~/DA_EXPT1/
cd ~/DA_EXPT1
./run
make clean -C ~/DA_EXPT1/

## (5) if analysis is written, update restart with analysis; otherwise, skip.
cd $TMPDIR
if [ -f ~/DA_EXPT1/output/analysis*.dta ]; then
   # (5.1) UPDATE RESTART FILES
   cp ~/DA_EXPT1/ensemble/coordinate.dta .
   cp ~/DA_EXPT1/output/analysis*.dta analysis.dta

   ls 1_ANHA4-*restart_0* > restart_files
   head -1 restart_files > name_example
   awk '{print length($0);}' name_example > name_length
   ./update.out
   rm restart_files name_example name_length

   # (5.2) SAVE ALL PRODUCED DATA FILES
   ##mv *background_nest.dta ~/DA_EXPT1/output/SAVE
   mv ~/DA_EXPT1/output/analysis*.dta ~/DA_EXPT1/output/SAVE
fi

## (6) save daily averages from TMP*
ls 1_ANHA4*grid_T* > output_files
head -1 output_files > name_example
awk '{print length($0);}' name_example > name_length

./DA_domain.out
mv *daily*.dta ~/ANHA4/ANHA4-EXPT1-S/
