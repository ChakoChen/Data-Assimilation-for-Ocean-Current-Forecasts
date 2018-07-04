program DA_cycle
   use mod_params, only : step 
   use mod_analysis
   use mod_matrix_A
   implicit none
   integer :: yyyy, mm, dd, hh, ff, ss, time(6)

   if (step) call A_matrix()     ! A matrix: run only 1 time before DA cycles

   open(unit=11,file='DA_time.txt')
   read (11,*) yyyy, mm, dd, hh, ff, ss
   close(11)

   time = (/yyyy,mm,dd,hh,ff,ss/)

   call analysis(time)

   stop
end program DA_cycle
