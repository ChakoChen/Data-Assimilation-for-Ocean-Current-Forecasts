! This stand-alone program writes a time file for DA to start with. The time 
! file is determined from the last snapshot output date from NEMO. This date 
! is the date for a new DA cycle. 
program DA_time
   implicit none
   integer :: name_len, yyyy, mm, dd, hh, ff, ss
   character(len=:), allocatable :: fname

   open(11,file='name_length',form='formatted',action='read')
   read(11,'(I3)') name_len
   close(11)

   allocate(character(len=name_len) :: fname)
   open(12,file='name_example',form='formatted',action='read')
   read(12,*) fname 
   close(12)

   ! e.g.: ANHA12-TEST02_1d_20020101_20020102_grid_U_0114.nc
   ! e.g.:  ANHA4-DASSIM_1d_20140702_20140704_grid_T_0016.nc
   read(fname(name_len-22:name_len-19),'(I4)') yyyy
   read(fname(name_len-18:name_len-17),'(I2)') mm
   read(fname(name_len-16:name_len-15),'(I2)') dd
   hh = 12
   ff = 0
   ss = 0

   open(unit=13,file='DA_time.txt')
   write(13,*) yyyy, mm, dd, hh, ff, ss
   close(13)

   stop
end program DA_time 
