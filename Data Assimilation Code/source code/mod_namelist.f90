module mod_namelist
   use mod_params, only : y_start, y_end, fname_var, data_pth, NS
   implicit none

   contains 
   subroutine namelists()
      implicit none
      integer :: y, m, d, n
      logical :: exist
      character(len=13) :: fname, fnames(NS)
      character :: fname2*18
      character :: year*4, month*2, day*2
     
      n = 0
      do y=y_start,y_end 
         do m=1,12
            do d=1,31
               write (year,'(I4)') y

               if (m<10) then
                  write(month,'(I1)') m
                  month = '0'//month(1:1)
               else
                  write(month,'(I2)') m
               endif

               if (d<10) then
                  write(day,'(I1)') d
                  day = '0'//day(1:1)
               else
                  write(day,'(I2)') d
               endif
  
               fname = year//month//day//fname_var 

               fname2 = data_pth//fname
               inquire(file=fname2,exist=exist)
               if (exist.eqv..true.) then
                  n = n+1
                  fnames(n) = fname
               endif

            enddo
         enddo
      enddo
 
      open (unit=15,file='data/namelist.txt', status='new', &
            access='sequential', form='formatted', action='write')
      do n=1,NS
         write (15,'(A13)') fnames(n)
      enddo
      close(15)

      return
   end subroutine namelists

end module mod_namelist
