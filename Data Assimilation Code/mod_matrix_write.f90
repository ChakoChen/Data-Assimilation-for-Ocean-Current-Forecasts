module mod_matrix_write
   implicit none
  
   contains
   subroutine writematrix(matrix,dim1,dim2,mat_name,name_length)
      implicit none
      integer, intent(in)   :: dim1, dim2
      real, intent(in)      :: matrix(dim1,dim2)
      integer, intent(in)   :: name_length
      character, intent(in) :: mat_name*name_length

      write(*,*) "*** Writing matrix "//mat_name//"..."

      open(unit=11,file='ensemble/'//mat_name//'matrix.dta',form='unformatted')
      write(11) matrix
      close(11)

      write(*,*) "    ...done."

      return
   end subroutine writematrix
  
end module mod_matrix_write
