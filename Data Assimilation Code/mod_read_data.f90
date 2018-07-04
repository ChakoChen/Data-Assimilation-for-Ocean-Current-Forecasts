module mod_read_data
   use netcdf
   use mod_params, only :NLONS, NLATS, NLVLS, NDIMS, NRECS, TMP_NAME, SAL_NAME, sub_x, sub_y, sub_xy
   implicit none

   contains
   subroutine readdata(tmp2,sal2,fname2)
      implicit none 
      character(len=18), intent(in)  :: fname2
      real, intent(out) :: tmp2(sub_x, sub_y, NLVLS)
      real, intent(out) :: sal2(sub_x, sub_y, NLVLS)

      real :: tmp(NLONS, NLATS, NLVLS)
      real :: sal(NLONS, NLATS, NLVLS)

      integer :: ncid, rec
      integer :: start(NDIMS), count(NDIMS)
      integer :: tmp_varid, sal_varid

      ! (1) Open the file 
      call check( nf90_open(fname2, nf90_nowrite, ncid) )

      ! (2) Get the varids of T and S
      call check( nf90_inq_varid(ncid, TMP_NAME, tmp_varid) )
      call check( nf90_inq_varid(ncid, SAL_NAME, sal_varid) )

      ! (3) Read T and S from the file, 1 record at a time
      count = (/ NLONS, NLATS, NLVLS, 1 /)
      start = (/ 1, 1, 1, 1 /)
      do rec = 1, NRECS
         start(4) = rec
         call check( nf90_get_var(ncid, tmp_varid, tmp, start = start, &
                                                          count = count) )
         call check( nf90_get_var(ncid, sal_varid, sal, start, count) )
      enddo
         
      ! (4) Close the file
      call check( nf90_close(ncid) )
      write(*,*) "*** SUCCESS Reading file ", fname2, "!"

      tmp2 = tmp(sub_xy(1):sub_xy(3),sub_xy(2):sub_xy(4),:)
      sal2 = sal(sub_xy(1):sub_xy(3),sub_xy(2):sub_xy(4),:)

      return
   end subroutine readdata
 
   subroutine check(status)
      integer, intent (in) :: status

      if (status /= nf90_noerr) then
         print *, trim(nf90_strerror(status))
         stop "Stopped"
      endif

      return
  end subroutine check
 
end module mod_read_data
