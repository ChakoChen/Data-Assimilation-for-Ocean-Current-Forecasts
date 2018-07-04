module mod_analysis
   use mod_params, only : output_pth, input_pth, N, NN, NLVLS, sub_y, sub_x, crt_bias, rgamma
   use mod_date
   use mod_read_data
   use mod_matrix_read
   use mod_matrix_W
   use mod_obs_sorting
   implicit none

   contains
   subroutine analysis(time)
      implicit none
      integer, intent(in) :: time(6)

      integer :: i,  M2(2), M                            ! M = M2(1)+M2(2)
      integer, parameter :: NRECS = 1
      character :: tag*8
      real :: tmp4D(sub_x,sub_y,NLVLS,NRECS), tmp(sub_x,sub_y,NLVLS)
      real :: sal4D(sub_x,sub_y,NLVLS,NRECS), sal(sub_x,sub_y,NLVLS)
      real, allocatable :: tmp_o(:), sal_o(:), yo(:)
      real, allocatable :: H(:,:), HXb(:), W(:,:) 
      real :: Xb(N), dX(N), bias(N)

      integer, allocatable :: Tindex3D(:,:), Sindex3D(:,:)

      real :: start, finish

      call cpu_time(start) 

      ! (0) write date from observation time
      call date(tag,time)

      ! (1) get the number of observations
      write(*,*) 'Preparing observational data...'   
      call sort_obs(M2,time) 
      M = sum(M2)
  
      ! (2) compute gain matrix W
      write(*,*) 'Computing gain matrix...'   
      call W_matrix(M2,M,time)
   
      ! (3) read in observation
      write(*,*) 'Updating the background with observational data...'   

      allocate(tmp_o(M2(1)), sal_o(M2(2)), yo(M))
      open(55,file='/home/chako/Argo/bias_nay/bins.dta',form='unformatted')
      read(55) tmp_o, sal_o
      close(55)
      yo(1:M2(1)) = tmp_o; yo(M2(1)+1:M) = sal_o
      write(*,*) '*** SUCCESS Sorted observation is read in!'   

      ! (4) read in background 
      open(55,file=input_pth//'background.dta',form='unformatted')
      read(55) tmp4D, sal4D 
      close(55)
      tmp = tmp4D(:,:,:,1); sal = sal4D(:,:,:,1)
      write(*,*) '*** SUCCESS Background is read in!'   

      call squeeze(Xb,tmp,sal)                       ! reshape tmp&sal to get Xb(N)

      ! (5) correct model bias
      if (crt_bias) then
         open(55,file=output_pth//'/bias/model_bias.dta',form='unformatted')
         read(55) bias
         close(55)
         write(*,*) '*** SUCCESS Model bias is read in!'

         Xb = Xb-bias
      endif

      ! (6) calculate increment
      allocate(H(M,N),HXb(M))
      call readmatrix(H,M,N,'H',1)
      HXb = matmul(H,Xb)
      deallocate(H)
      ! IMPORTANT: find topography points in model output (=0.0): model topo points
      ! different from argo topo points
      do i=1,M
         if (HXb(i)==0.0) then
            yo(i) = 0.0
         endif
      enddo
      !!========================================================================
      !!                       Check innovations                              !!
      allocate(Tindex3D(M2(1),4), Sindex3D(M2(2),4))                          !!
      open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')!!
      read(55) Tindex3D, Sindex3D                                             !!
      close(55)                                                               !!
                                                                              !!
      open(33,file='ensemble/check_innovation'//tag//'.txt',form='formatted') !!
      do i=1,M                                                                !!
         if (i<=M2(1)) then                                                   !!
            write(33,'(I3,I3,I3,I3,F24.16,F24.16)') Tindex3D(i,4),&           !! 
                Tindex3D(i,1), Tindex3D(i,2), Tindex3D(i,3), yo(i), HXb(i)    !!
         else                                                                 !!
            write(33,'(I3,I3,I3,I3,F24.16,F24.16)') Sindex3D(i-M2(1),4),&     !!
      Sindex3D(i-M2(1),1),Sindex3D(i-M2(1),2),Sindex3D(i-M2(1),3),yo(i),HXb(i)!!
         endif                                                                !!
      enddo                                                                   !!
      close(33)                                                               !!
      deallocate(Tindex3D, Sindex3D)                                          !!
      !!========================================================================
      yo = yo-HXb

      allocate(W(N/2,M))
      call readmatrix(W,N/2,M,'WT',2) 
      dX(1:N/2) = matmul(W,yo)
      call readmatrix(W,N/2,M,'WS',2) 
      dX(N/2+1:N) = matmul(W,yo)
      deallocate(W)
 
      if (crt_bias) then
         bias = bias-rgamma*dX

         open(55,file=output_pth//'/bias/model_bias.dta',form='unformatted')
         write(55) bias
         close(55)
         write(*,*) '*** SUCCESS Model bias is updated!'
      endif

      ! (7) get analysis
      if ((maxval(dX(1:N/2))>10.0).or.(minval(dX(1:N/2))<-10.0)) then
         write(*,*) '*** WARNING T increment is abnormal!'
         write(*,*) '*** WARNING No observations assimilated!'
         Xb = Xb
      elseif ((maxval(dX(N/2+1:N))>5.0).or.(minval(dX(N/2+1:N))<-5.0)) then
         write(*,*) '*** WARNING S increment is abnormal!'
         write(*,*) '*** WARNING No observations assimilated!'
         Xb = Xb
      else
         Xb = Xb+dX                  ! acutally Xb=Xa 
      endif
      call expand(tmp,sal,Xb)        ! analysis of tmp & sal 
      write(*,*) '*** SUCCESS Analysis is computed!'   

      ! (8) save analysis as restart
      open(55,file=output_pth//'analysis'//tag//'.dta',form='unformatted')
      write(55) tmp, sal 
      close(55)
      write(*,*) '*** SUCCESS Analysis is saved!'
   
      call cpu_time(finish)
      print '("Time = ",f10.2," minutes.")',(finish-start)/60.0

      return
   end subroutine analysis

   subroutine squeeze(var,var1,var2)
      implicit none
      real, intent(in)  :: var1(sub_x,sub_y,NLVLS), var2(sub_x,sub_y,NLVLS)
      real, intent(out) :: var(N)
      integer :: i, j, k, r

      r = 0
      do k=1,NLVLS
         do j=1,sub_y
            do i=1,sub_x
               r = r+1
               var(r) = var1(i,j,k)
            enddo
         enddo
      enddo 
      do k=1,NLVLS 
         do j=1,sub_y 
            do i=1,sub_x
               r = r+1
               var(r) = var2(i,j,k)
            enddo
         enddo
      enddo

      return
   end subroutine squeeze

   subroutine expand(var1,var2,var)
      implicit none
      real, intent(in)  :: var(N)
      real, intent(out) :: var1(sub_x,sub_y,NLVLS), var2(sub_x,sub_y,NLVLS)
      integer :: i, j, k, r

      r = 0
      do k=1,NLVLS 
         do j=1,sub_y 
            do i=1,sub_x
               r = r+1
               var1(i,j,k) = var(r)
            enddo
         enddo
      enddo
      do k=1,NLVLS
         do j=1,sub_y
            do i=1,sub_x
               r = r+1
               var2(i,j,k) = var(r)
            enddo
         enddo
      enddo

      return
   end subroutine expand

end module mod_analysis  
