module mod_matrix_A
   use mod_params, only : data_pth, NLVLS, sub_y, sub_x, NS, DN, NN, N
   use mod_namelist
   use mod_read_data
   use mod_read_coor
   use mod_matrix_read
   use mod_matrix_write
   implicit none

   contains
   subroutine A_matrix()
      ! tmp7, sal7: 5-day mean
      ! tmp1, sal1: 1-day mean
      ! tmpp, salp: the anomalies with respect to the mean
      ! tmpd, sald: the deviation from the mean
      ! A(N,NN): ensemble matrix, N=NLVLS*sub_y*sub_x*2, NN is the ensemble number
      implicit none
      integer :: i, j, k, m, x, s, list
      character :: fname*15, fname2*18
      logical :: exist
      real :: tmp(sub_x,sub_y,NLVLS), sal(sub_x,sub_y,NLVLS)
      real :: tmps(sub_x,sub_y,NLVLS), sals(sub_x,sub_y,NLVLS)
      real :: tmpp(sub_x,sub_y,NLVLS), salp(sub_x,sub_y,NLVLS)
      real :: tmpd(sub_x,sub_y,NLVLS), sald(sub_x,sub_y,NLVLS)
      real, allocatable :: A(:,:), AT(:,:), AS(:,:)

      ! (0) initialize summation and std terms
      tmps = 0.0; sals = 0.0
      tmpd = 0.0; sald = 0.0

      ! (1) Write namelist.txt for the ensemble pool data files
      call namelists()

      ! (2) Get coordinates for T&S from a sample data file 
      open (unit=15,file=data_pth//'namelist.txt', status='old', &
            access='sequential', form='formatted', action='read')
      read (15,'(A13)') fname
      close(15)
      fname2 = data_pth//fname
      call readcoor(fname2)

      ! (3) Construct Amean from every 6 day sampling of 2-year run 
      OPEN (unit=15,file=data_pth//'namelist.txt', status='old', &
            access='sequential', form='formatted', action='read')

      m = 0 
      s = 0
      do list=1,NS
         s = s+1
         read (15,'(A13)') fname
         if (s==DN) then
            fname2 = data_pth//fname
            call readdata(tmp,sal,fname2)
         
            tmps = tmps+tmp
            sals = sals+sal
            m = m+1
            s = 0
         endif
      enddo

      tmps = tmps/real(m)
      sals = sals/real(m)

      CLOSE(15)

      open(unit=12,file='ensemble/ensemble_mean_tmp.dta',form='unformatted')
      write(12) tmps
      close(12)
      open(unit=22,file='ensemble/ensemble_mean_sal.dta',form='unformatted')
      write(22) sals
      close(22)

      ! (4) Construct A'=A-Amean
      allocate(A(N,NN))

      OPEN (unit=15,file=data_pth//'namelist.txt', status='old', &
            access='sequential', form='formatted', action='read')

      m = 0
      s = 0
      do list=1,NS
         s = s+1
         read (15,'(A13)') fname

         if (s==DN) then
            fname2 = data_pth//fname
            call readdata(tmp,sal,fname2)

            tmpp = tmp-tmps
            salp = sal-sals
            m = m+1
            s = 0

            x = 0
            do k = 1,NLVLS            ! construct A' (NxNN) from Ai' (Nx1)
               do j = 1,sub_y
                  do i = 1,sub_x
                     x = x+1
                     A(x,m) = tmpp(i,j,k)
                  enddo
               enddo
            enddo
            do k = 1,NLVLS
               do j = 1,sub_y
                  do i = 1,sub_x
                     x = x+1
                     A(x,m) = salp(i,j,k)
                  enddo
               enddo
            enddo

            do k=1,NLVLS
               do j=1,sub_y
                  do i=1,sub_x
                     tmpd(i,j,k) = tmpd(i,j,k)+tmpp(i,j,k)**2.0
                     sald(i,j,k) = sald(i,j,k)+salp(i,j,k)**2.0
                  enddo
               enddo
            enddo
         endif
      enddo

      CLOSE(15)

      do k=1,NLVLS
         do j=1,sub_y
            do i=1,sub_x
               tmpd(i,j,k) = (tmpd(i,j,k)/real(m))**0.5
               sald(i,j,k) = (sald(i,j,k)/real(m))**0.5
            enddo
         enddo
      enddo

      open(unit=12,file='ensemble/ensemble_sprd_tmp.dta',form='unformatted')
      write(12) tmpd
      close(12)
      open(unit=22,file='ensemble/ensemble_sprd_sal.dta',form='unformatted')
      write(22) sald
      close(22)

      open(unit=11,file='ensemble/AT0matrix.dta',form='unformatted')
      do i=1,N/2
         write(11) (A(i,j),j=1,NN)
      enddo
      close(11)

      open(unit=11,file='ensemble/AS0matrix.dta',form='unformatted')
      do i=N/2+1,N
         write(11) (A(i,j),j=1,NN)
      enddo
      close(11)
  
      call writematrix(A,N,NN,'A',1)
      deallocate(A)

      allocate(AT(N/2,NN))
      call readmatrix(AT,N/2,NN,'AT0',3,1)
      call writematrix(AT,N/2,NN,'AT',2)
      deallocate(AT)

      allocate(AS(N/2,NN))
      call readmatrix(AS,N/2,NN,'AS0',3,1)
      call writematrix(AS,N/2,NN,'AS',2)
      deallocate(AS)

      stop
   end subroutine A_matrix

end module mod_matrix_A
