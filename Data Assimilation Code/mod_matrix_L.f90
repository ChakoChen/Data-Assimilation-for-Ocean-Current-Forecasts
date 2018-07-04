module mod_matrix_L
   use mod_params, only : NLVLS, sub_y, sub_x, N, loc_Lh, loc_Lv, Lh, Lv
   use mod_matrix_write
   use mod_matrix_read
   implicit none

   contains
   subroutine L_matrix(M2,M)
      implicit none
      integer, intent(in) :: M2(2), M
      real, allocatable   :: LHT(:,:), HLHT(:,:)

      integer :: i, j, x, y, z
      integer :: p1(3), p2(3)
      integer :: Tindex1D(M2(1)), Sindex1D(M2(2))
      integer :: Tindex3D(M2(1),4), Sindex3D(M2(2),4)

      real :: lons(sub_x,sub_y), lats(sub_x,sub_y), depth(NLVLS)
      real :: dh, dz

      open(unit=11,file='ensemble/coordinate.dta',form='unformatted')
      read(11) lons, lats, depth
      close(11)

      open(55,file='/home/chako/Argo/bias_nay/Index1D.dta',form='unformatted')
      read(55) Tindex1D, Sindex1D
      close(55)

      open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')
      read(55) Tindex3D, Sindex3D
      close(55)

      ! (1) compute LHT
      allocate(LHT(N,M))
      LHT = 0.0
      i = 0
      do z=1,NLVLS
         do y=1,sub_y
            do x=1,sub_x
               i = i+1
               do j=1,M2(1)
                  p1 = (/x,y,z/)
                  p2 = (/Tindex3D(j,1),Tindex3D(j,2),Tindex3D(j,3)/)
                  dh = hav_dis(lats(x,y),lons(x,y),lats(p2(1),p2(2)),lons(p2(1),p2(2)))
                  dz = abs(depth(z)-depth(p2(3)))  
                  LHT(i,j) = corrcoef(dh,dz)
               enddo
            enddo
         enddo
      enddo
      do z=1,NLVLS
         do y=1,sub_y
            do x=1,sub_x
               i = i+1
               do j=1,M2(2)
                  p1 = (/x,y,z/)
                  p2 = (/Sindex3D(j,1),Sindex3D(j,2),Sindex3D(j,3)/)
                  dh = hav_dis(lats(x,y),lons(x,y),lats(p2(1),p2(2)),lons(p2(1),p2(2)))
                  dz = abs(depth(z)-depth(p2(3)))
                  LHT(i,j+M2(1)) = corrcoef(dh,dz)
               enddo
            enddo
         enddo
      enddo
      LHT(N/2+1:N,1:M2(1)) = LHT(1:N/2,1:M2(1))
      LHT(1:N/2,M2(1)+1:M) = LHT(N/2+1:N,M2(1)+1:M)

      open(55,file='ensemble/LHTT0matrix.dta',form='unformatted')
      do i=1,N/2
         write(55) (LHT(i,j), j=1,M2(1))
      enddo
      close(55)

      open(55,file='ensemble/LHSS0matrix.dta',form='unformatted')
      do i=N/2+1,N
         write(55) (LHT(i,j), j=M2(1)+1,M)
      enddo
      close(55)

      ! (2) compute HLHT from H and LHT
      allocate(HLHT(M,M))
      HLHT = 0.0
      do j=1,M
         do i=1,M2(1)
            HLHT(i,j) = LHT(Tindex1D(i),j) 
         enddo
      enddo   
      do j=1,M
         do i=M2(1)+1,M
            HLHT(i,j) = LHT(N/2+Sindex1D(i-M2(1)),j) 
         enddo
      enddo

      call writematrix(HLHT,M,M,'HLHT',4)
      deallocate(LHT,HLHT)

   return
   end subroutine L_matrix

   real function corrcoef(L,D)
      implicit none
      real, intent(in) :: L, D  ! horizontal distance: H; vertical distance: D 
      real :: c
      
      if (loc_Lh .and. loc_Lv) then
         c = exp( -L**2.0/(2.0*(Lh**2.0)) - D**2.0/(2.0*(Lv**2.0)) )
      elseif (loc_Lh .and. (loc_Lv == .false.)) then
         c = exp( -L**2.0/(2.0*(Lh**2.0)))
      elseif ((loc_Lh == .false.) .and. loc_Lv) then
         c = exp(- D**2.0/(2.0*(Lv**2.0)))
      else
         c = 1.0
      endif
      corrcoef = c  

      return 
   end function corrcoef

   real function hav_dis(lat1,lon1,lat2,lon2)
      implicit none
      real, intent(in) :: lat1, lon1, lat2, lon2
      real, parameter :: R = 6371.0, pi = 4.0*atan(1.0)
      real :: hav, dlat, dlon, rlat1, rlat2
 
      dlat  = (lat1-lat2)*pi/180.0
      dlon  = (lon1-lon2)*pi/180.0
      rlat1 = lat1*pi/180.0
      rlat2 = lat2*pi/180.0
     
      hav = 2.0*R*asin(sqrt( sin(dlat/2.0)**2.0+cos(rlat1)*cos(rlat2)*sin(dlon/2.0)**2.0 )) 
      hav_dis = hav

      return
   end function hav_dis

end module mod_matrix_L 
