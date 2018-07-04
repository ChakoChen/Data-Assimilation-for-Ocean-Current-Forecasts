module mod_matrix_read
   implicit none
  
   contains
   subroutine readmatrix(matrix,dim1,dim2,mat_name,name_length,opt)
      implicit none
      integer, intent(in)   :: name_length
      integer, intent(in)   :: dim1, dim2
      character, intent(in) :: mat_name*name_length
      real, intent(out)     :: matrix(dim1,dim2)
      integer, intent(in), optional :: opt

      integer :: i, j

      write(*,*) "*** Reading matrix "//mat_name//"..."

      open(unit=11,file='ensemble/'//mat_name//'matrix.dta',form='unformatted')
      if (present(opt)) then
         do i=1,dim1
            read(11) (matrix(i,j),j=1,dim2)
         enddo
      else
         read(11) matrix
      endif
      close(11)

      write(*,*) "    ...done."

      return
   end subroutine readmatrix
  
end module mod_matrix_read
