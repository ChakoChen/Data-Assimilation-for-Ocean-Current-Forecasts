module mod_read_coor
   use netcdf
   use mod_params, only : NLONS, NLATS, NLVLS, LON_NAME, LAT_NAME, LVL_NAME, sub_x, sub_y, sub_xy
   implicit none

   contains
   subroutine readcoor(fname2)
      implicit none 
      character (len=18), intent(in) :: fname2 

      integer :: ncid
      integer :: lat_varid, lon_varid, lvl_varid
      real :: lons(NLONS,NLATS), lats(NLONS,NLATS), depth(NLVLS) ! reversed order 
      real :: lons2(sub_x,sub_y), lats2(sub_x,sub_y) 

      ! (1) Open the file. 
      call check( nf90_open(fname2, nf90_nowrite, ncid) )

      ! (2) Get the varids of longitude, latitude and depth
      call check( nf90_inq_varid(ncid, LON_NAME, lon_varid) )
      call check( nf90_inq_varid(ncid, LAT_NAME, lat_varid) )
      call check( nf90_inq_varid(ncid, LVL_NAME, lvl_varid) )

      ! (3) Read longitude and latitude data
      call check( nf90_get_var(ncid, lon_varid, lons) )
      call check( nf90_get_var(ncid, lat_varid, lats) )
      call check( nf90_get_var(ncid, lvl_varid, depth) )

      ! (4) Close the file 
      call check( nf90_close(ncid) )
 
      ! (5) Write out the coordinates
      lons2 = lons(sub_xy(1):sub_xy(3),sub_xy(2):sub_xy(4))
      lats2 = lats(sub_xy(1):sub_xy(3),sub_xy(2):sub_xy(4))
      open(unit=11,file='ensemble/coordinate.dta',form='unformatted')
      write(11) lons2, lats2, depth 
      close(11)

      write(*,*) "*** SUCCESS Coordinate is written!"

      return
   end subroutine readcoor

   subroutine check(status)
      integer, intent (in) :: status

      if (status /= nf90_noerr) then
         print *, trim(nf90_strerror(status))
         stop "Stopped"
      endif

      return
  end subroutine check

end module mod_read_coor
