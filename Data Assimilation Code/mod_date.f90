module mod_date
   implicit none

   contains
   subroutine date(flag,times)
      implicit none
      integer, intent(in) :: times(6)
      character(len=8), intent(out) :: flag

      character :: year*4, month*2, day*2

      write(year,'(I4)') times(1)
      if (times(2)<10) then
         write(month,'(I1)') times(2)
         month = '0'//month
      else
         write(month,'(I2)') times(2)
      endif
      if (times(3)<10) then
         write(day,'(I1)') times(3)
         day = '0'//day
      else
         write(day,'(I2)') times(3)
      endif

      flag = year//month//day

      return
   end subroutine date

end module mod_date
