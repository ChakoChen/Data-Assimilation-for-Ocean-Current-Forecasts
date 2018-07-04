module mod_obs_sorting 
   use mod_params, only : max_argo, N, sub_x, sub_y, NLVLS
   use mod_obs_superobing
   implicit none
 
   contains
   subroutine sort_obs(M2,time)
      implicit none
      integer, intent(in)  :: time(6)
      integer, intent(out) :: M2(2)                   ! # of T&S observations

      character :: filename*14
      integer   :: argos                              ! total number of argo profiles
      integer   :: loc(2)                             ! loc(2)=(lon or i) and (lat or j)
      integer   :: lvl(2)                             ! # of stacks of bins of T & S

      integer, allocatable :: locs(:,:)               ! horizontal locations of argo profiles
      integer, allocatable :: Mt(:), Ms(:)            ! numbers of T&S in each argo profile
      logical   :: exist
      
      integer, allocatable :: index1D(:), index3D(:,:)       ! indices of obs in 1D/3D model grids
      integer, allocatable :: Tindex1Ds(:),   Sindex1Ds(:)   ! indices of obs in 1D model grids
      integer, allocatable :: Tindex3Ds(:,:), Sindex3Ds(:,:) ! indices of obs in 3D model grids
      integer, allocatable :: lvl_t(:), lvl_s(:)             ! # of bins of T and S
      real, allocatable    :: tmp(:), sal(:)                 ! T&S from 1 Argo
      real, allocatable    :: tmps(:), sals(:)               ! T&S from all Argo

      integer :: i, j, k, p, ind1, ind2

      ! (1) check the number of the argo profiles on 'date'
      argos = 0
      do p=1,max_argo
         call argo_name(filename,time,p)
         inquire(file='/home/chako/Argo/daily/'//filename,exist=exist)
         if (exist.eqv..true.) then
            argos = argos+1
         else
            exit
         endif
         
      enddo

      if (argos==0) then 
         write(*,*) "*** STOP No Argo profile is read in."
         stop 
      else
         write(*,*) argos, 'Argo profiles are read in.'
      endif       

      ! (2) read in all argos and record horizontal indices and numbers of bins
      allocate(locs(argos,2),Mt(argos),Ms(argos))

      do p=1,argos
         call argo_name(filename,time,p)
         call bins(loc,lvl,filename)
         locs(p,1) = loc(1)        ! location: loc(n,1)=lon=i
         locs(p,2) = loc(2)        ! location: loc(n,2)=lat=j
         Mt(p) = lvl(1)            ! number of T
         Ms(p) = lvl(2)            ! numbers of S
      enddo 

      M2(1) = sum(Mt); M2(2) = sum(Ms) 
      if (sum(M2)==0) stop "*** STOP No T and S is read in!"
      if (M2(1)==0) write(*,*) "*** WARNING No T is read in!"
      if (M2(2)==0) write(*,*) "*** WARNING No S is read in!"
      write(*,'(A45,I3,A1,I3,A1)')'*** SUCCESS Numbers of the bins of T, S are ',M2(1),',',M2(2),'!' 
      allocate(Tindex1Ds(M2(1)), Tindex3Ds(M2(1),4), tmps(M2(1)))
      allocate(Sindex1Ds(M2(2)), Sindex3Ds(M2(2),4), sals(M2(2)))

      ! (3) read in the obs and rearrange T&S, along with their 1D&3D indices
      ! (3.1) First, combine T from all Argos
      ind2 = 0
      do p=1,argos

         if (Mt(p)==0) cycle

         allocate(lvl_t(Mt(p)), tmp(Mt(p)))
         allocate(index1D(Mt(p)), index3D(Mt(p),4))

         call argo_name(filename,time,p)
         open(55,file='/home/chako/Argo/bias_nay/bins'//filename,form='unformatted')
         read(55) lvl_t, tmp
         close(55)

         do k=1,Mt(p)
            index1D(k) = sub_x*sub_y*(lvl_t(k)-1)+sub_x*(locs(p,2)-1)+locs(p,1)
            if (index1D(k)>N/2) stop "*** ERROR 1D index of T greater than N/2!"
            index3D(k,1) = locs(p,1)
            index3D(k,2) = locs(p,2)
            index3D(k,3) = lvl_t(k)
            index3D(k,4) = p
         enddo
         ind1 = ind2+1
         ind2 = ind2+k-1 
         Tindex1Ds(ind1:ind2) = index1D
         Tindex3Ds(ind1:ind2,:) = index3D
         tmps(ind1:ind2) = tmp
         
         deallocate(lvl_t,tmp)
         deallocate(index1D,index3D)
      enddo

      ! (3.2) Second, combine S from all argos
      ind2 = 0
      do p=1,argos

         if (Ms(p)==0) cycle

         allocate(lvl_t(Mt(p)), tmp(Mt(p)))
         allocate(lvl_s(Ms(p)), sal(Ms(p)))
         allocate(index1D(Ms(p)), index3D(Ms(p),4))
         
         call argo_name(filename,time,p)
         open(55,file='/home/chako/Argo/bias_nay/bins'//filename,form='unformatted')
         read(55) lvl_t, tmp, lvl_s, sal
         close(55)

         do k=1,Ms(p)
            index1D(k) = sub_x*sub_y*(lvl_s(k)-1)+sub_x*(locs(p,2)-1)+locs(p,1)
            if (index1D(k)>N/2) stop "*** ERROR 1D index of S greater than N/2!"
            index3D(k,1) = locs(p,1)
            index3D(k,2) = locs(p,2)
            index3D(k,3) = lvl_s(k)
            index3D(k,4) = p
         enddo
         ind1 = ind2+1
         ind2 = ind2+k-1
         Sindex1Ds(ind1:ind2) = index1D
         Sindex3Ds(ind1:ind2,:) = index3D
         sals(ind1:ind2) = sal
        
         deallocate(lvl_t,tmp)
         deallocate(lvl_s,sal)
         deallocate(index1D,index3D)
      enddo          
 
      ! (4) sort obs_Index, tmpn and saln acording to obs_Index1D
      call sort(Tindex1Ds,Tindex3Ds,tmps,M2(1))
      call sort(Sindex1Ds,Sindex3Ds,sals,M2(2))
       
      open(55,file='/home/chako/Argo/bias_nay/Index1D.dta',form='unformatted')
      write(55) Tindex1Ds, Sindex1Ds
      close(55)
      open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')
      write(55) Tindex3Ds, Sindex3Ds
      close(55)
      write(*,*) '*** SUCCESS Indices of observations are written!'

      open(55,file='/home/chako/Argo/bias_nay/bins.dta',form='unformatted')
      write(55) tmps, sals
      close(55)      
      write(*,*) '*** SUCCESS Sorted data for all argos are written!'
      return
   end subroutine sort_obs

!========================================================================================
   subroutine argo_name(argoname,date,tag)
      implicit none
      character, intent(out) :: argoname*14
      integer, intent(in)    :: date(3)
      integer, intent(in)    :: tag

      character :: year*4, month*2, day*2, tags*2

      write(year,'(I4)') date(1)

      if (date(2)<10) then
         write(month,'(I1)') date(2)
         month = '0'//month(1:1)
      else
         write(month,'(I2)') date(2)
      endif

      if (date(3)<10) then
         write(day,'(I1)') date(3)
         day = '0'//day(1:1)
      else
         write(day,'(I2)') date(3)
      endif

      if (tag<10) then
         write(tags,'(I1)') tag
         tags = '0'//tags(1:1)
      else
         write(tags,'(I2)') tag
      endif

      argoname = year//month//day//tags//'.dta'

      return
   end subroutine argo_name

!========================================================================================
   subroutine sort(Index1D,Index3D,var,recs)
      implicit none
      integer, intent(in)    :: recs 
      integer, intent(inout) :: Index1D(recs)
      integer, intent(inout) :: Index3D(recs,4)
      real, intent(inout)    :: var(recs,2)
      integer :: i, location
       
      do i=1,recs-1
         location = FindMinimum(Index1D,i,recs)
         call swap_int(Index1D(i),Index1D(location))

         call swap_int(Index3D(i,1),Index3D(location,1))
         call swap_int(Index3D(i,2),Index3D(location,2))
         call swap_int(Index3D(i,3),Index3D(location,3))
         call swap_int(Index3D(i,4),Index3D(location,4))

         call swap_real(var(i,1),var(location,1))
      enddo

      return
   end subroutine sort

!========================================================================================
   integer function FindMinimum(x,start,final)
      implicit none
      integer, intent(in) :: x(1:)      
      integer, intent(in) :: start, final
      integer :: minimum, location, i

      minimum = x(start)
      location = start
      do i=start+1,final
         if (x(i)<minimum) then
            minimum = x(i)
            location = i
         endif
      enddo
      FindMinimum = location
   
      return
   end function FindMinimum        

!========================================================================================
   subroutine swap_int(a,b)
      implicit none
      integer, intent(inout) :: a, b
      integer :: temp
 
      temp = a
      a = b
      b = temp 

      return
   end subroutine swap_int

!========================================================================================
   subroutine swap_real(a,b)
      implicit none
      real, intent(inout) :: a, b
      real :: temp
 
      temp = a
      a = b
      b = temp 

      return
   end subroutine swap_real

end module mod_obs_sorting
