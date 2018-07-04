module mod_obs_superobing
   use mod_params, only : sub_x, sub_y, NLVLS
   implicit none

   contains
   subroutine bins(loc,lvl,filename)
      implicit none
      character, intent(in) :: filename*14        ! argo file name
      integer, intent(out)  :: loc(2)             ! (lon or i)- and (lat or j)-direction
      integer, intent(out)  :: lvl(2)             ! # of bins of T and S

      real :: lats_m(sub_x,sub_y)                 ! NEMO lat
      real :: lons_m(sub_x,sub_y)                 ! NEMO lon 
      real :: dpt_m(NLVLS)                        ! NEMO depth

      integer           :: recs                   ! number of the argo data records
      real, allocatable :: variables(:,:)         ! argo variables: lon,lat,dpt,tmp,sal
      real, allocatable :: lons_o(:), lats_o(:)   ! lats, lons of the argo profile
      real, allocatable :: dpts_o(:)              ! depths of the argo profile
      real, allocatable :: tmps(:), sals(:)       ! temp and sali of the profile

      real    :: lon_o, lat_o                     ! lon, lat of the argo profile
      real    :: dpt_o_min, dpt_o_max             ! min and max depths of the argo profile
      real    :: m_o(sub_x,sub_y)                 ! diff. between coor. of model and argo
      integer :: lvls                             ! # of the bins of the argo profile

      real, allocatable    :: tmp(:), sal(:)           ! T/S (mean) within each bin
      real, allocatable    :: tmp_save(:), sal_save(:) ! T/S (not NaN) within each bin
      integer, allocatable :: lvl_t(:), lvl_s(:)       ! number of bins of T, S

      integer   :: i, j, k, z, mt, ms, n, m

      ! (1) find the lon, lat, depths of super-obed bins
      open(55,file='/home/chako/Argo/daily/'//filename,form='unformatted',access='stream')
      read(55) recs
      allocate(variables(recs,6))
      read(55) variables 
      close(55)
      
      allocate(lons_o(recs),lats_o(recs),dpts_o(recs),tmps(recs),sals(recs))
      lons_o = variables(:,1)
      lats_o = variables(:,2)
      dpts_o = variables(:,3)
      tmps = variables(:,4)
      sals = variables(:,5)
      deallocate(variables)

      !--------------------------------------------------------------------------------------
      ! (1.1) find the closest model grid point (lon,lat) to the co-located vertical bins 
      open(55,file='ensemble/coordinate.dta',form='unformatted')
      read(55) lons_m, lats_m, dpt_m
      close(55)

      n = 0; lon_o = 0.0
      m = 0; lat_o = 0.0
      do i=1,recs
         if (.NOT.isnan(lons_o(i))) then
            n = n+1
            lon_o = lon_o+lons_o(i)
         endif
         if (.NOT.isnan(lats_o(i))) then
            m = m+1
            lat_o = lat_o+lats_o(i)
         endif 
      enddo
      lon_o = lon_o/n
      lat_o = lat_o/m 

      do j=1,sub_y
         do i=1,sub_x
            m_o(i,j) = abs(lons_m(i,j)-lon_o)+abs(lats_m(i,j)-lat_o)
         enddo
      enddo
      loc = minloc(m_o)

      ! (1.2) determine the levels that the vertical bins at 
      dpt_o_min = dpts_o(1)
      dpt_o_max = dpts_o(recs)
      
      lvl = -1 

      do k=2,NLVLS-1
         if (dpt_o_min>=(dpt_m(k-1)+dpt_m(k))/2.0.and.&
             dpt_o_min<(dpt_m(k)+dpt_m(k+1))/2.0) then
            lvl(1) = k
            exit
         endif
      enddo
      if (lvl(1)<0.and.dpt_o_min<(dpt_m(1)+dpt_m(2))/2.0) lvl(1) = 1
      if (lvl(1)<0.and.dpt_o_min>=(dpt_m(NLVLS-1)+dpt_m(NLVLS))/2.0) lvl(1) = NLVLS

      do k=2,NLVLS-1
         if (dpt_o_max>=(dpt_m(k-1)+dpt_m(k))/2.0.and.&
             dpt_o_max<(dpt_m(k)+dpt_m(k+1))/2.0) then
            lvl(2) = k 
            exit
         endif
      enddo
      if (lvl(2)<0.and.dpt_o_max<(dpt_m(1)+dpt_m(2))/2.0) lvl(2) = 1
      if (lvl(2)<0.and.dpt_o_max>=(dpt_m(NLVLS-1)+dpt_m(NLVLS))/2.0) lvl(2) = NLVLS

      if (product(lvl)<0) stop "*** Error in finding vertial bins!"

      !--------------------------------------------------------------------------------------
      ! (2) compute the profile/bins of tmp and sal
      lvls = lvl(2)-lvl(1)+1
      allocate(tmp(lvls),sal(lvls)) 

      ! (2.1) compute the mean of T&S in each bin
      z = 0; tmp = 0.0; sal = 0.0
      do k=lvl(1),lvl(2)
         z = z+1

         mt = 0; ms = 0
         if (k==1) then
            do i=1,recs
               if (dpts_o(i)<(dpt_m(k)+dpt_m(k+1))/2.0) then
                  if (isnan(tmps(i)).eq..false.) then
                     mt = mt+1 
                     tmp(z) = tmp(z)+tmps(i)
                  endif
                  if (isnan(sals(i)).eq..false.) then 
                     ms = ms+1
                     sal(z) = sal(z)+sals(i)
                  endif
               endif
            enddo
         elseif (k==NLVLS) then
            do i=1,recs
               if (dpts_o(i)>=(dpt_m(k-1)+dpt_m(k))/2.0) then
                  if (isnan(tmps(i)).eq..false.) then
                     mt = mt+1 
                     tmp(z) = tmp(z)+tmps(i)
                  endif
                  if (isnan(sals(i)).eq..false.) then 
                     ms = ms+1
                     sal(z) = sal(z)+sals(i)
                  endif
               endif
            enddo
         else
            do i=1,recs
               if (dpts_o(i)>=(dpt_m(k-1)+dpt_m(k))/2.0.and.&
                   dpts_o(i)<(dpt_m(k)+dpt_m(k+1))/2.0) then
                  if (isnan(tmps(i)).eq..false.) then
                     mt = mt+1
                     tmp(z) = tmp(z)+tmps(i)
                  endif
                  if (isnan(sals(i)).eq..false.) then 
                     ms = ms+1 
                     sal(z) = sal(z)+sals(i)
                  endif
               endif
            enddo
         endif
      
         tmp(z) = tmp(z)/real(mt)
         sal(z) = sal(z)/real(ms) 
      enddo
      
      ! (2.2) find and save the bins that are not NaNs
      mt = 0; ms = 0 
      do k=1,lvls
         if (isnan(tmp(k)).eq..false.) then
            mt = mt+1
         endif
         if (isnan(sal(k)).eq..false.) then
            ms = ms+1
         endif
      enddo
         
      allocate(tmp_save(mt),sal_save(ms),lvl_t(mt),lvl_s(ms)) 
      mt = 0; ms = 0; z = 0
      do k=lvl(1),lvl(2)
         z = z+1
         if (isnan(tmp(z)).eq..false.) then
            mt = mt+1
            lvl_t(mt) = k
            tmp_save(mt) = tmp(z) 
         endif
         if (isnan(sal(z)).eq..false.) then
            ms = ms+1
            lvl_s(ms) = k
            sal_save(ms) = sal(z)
         endif
      enddo

      lvl(1) = mt        ! number of bins with T values
      lvl(2) = ms        ! number of bins with S values

      !--------------------------------------------------------------------------------------
      ! (3) save the bins with size of lvl(1) for T and lvl(2) for S
      open(55,file='/home/chako/Argo/bias_nay/bins'//filename,form='unformatted')
      write(55) lvl_t, tmp_save, lvl_s, sal_save
      close(55)
      write(*,*) '*** SUCCESS Unsorted Argo data for '//filename//' is written!'

      deallocate(tmp,sal,tmp_save,sal_save,lvl_t,lvl_s)

      return
   end subroutine bins 

!========================================================================================
   real function mean(x,n)
      implicit none
      integer, intent(in) :: n
      real, intent(in) :: x(n)
      integer :: i, n2
      real :: m  
 
      m = 0.0; n2 = 0
      do i=1,n
         if (isnan(x(i)).eq..false.) then
            n2=n2+1
            m=m+x(i)
         endif
      enddo
      m = m/real(n2) 
      mean = m

      return
   end function mean

!========================================================================================
   real function std(x,n)
      implicit none
      integer, intent(in) :: n
      real, intent(in) :: x(n)
      integer :: i, n2
      real :: s, m 
  
      m = mean(x,n) 
      s = 0.0; n2 = 0
      do i=1,n
         if (isnan(x(i)).eq..false.) then 
            n2=n2+1
            s=s+(x(i)-m)**2.0
         endif
      enddo
      s = sqrt(s/real(n2)) 
      std = s

      return
   end function std

end module mod_obs_superobing
