module mod_matrix_W
   use mod_params, only : N, NN, alpha, localize
   use mod_date
   use mod_matrix_read
   use mod_matrix_write
   use mod_matrix_inverse
   use mod_matrix_H
   use mod_matrix_L
   use mod_matrix_R
   implicit none

   contains
   subroutine W_matrix(M2,M,time)
      implicit none
      integer, intent(in) :: M2(2), M
      integer, intent(in) :: time(6)

      character :: tag*8
      real, allocatable :: WT(:,:), WS(:,:)
      real, allocatable :: AHAT1(:,:), AHAS1(:,:), AHAT2(:,:), AHAS2(:,:)
      real, allocatable :: LHTT(:,:), LHSS(:,:)

      real :: HA(M,NN), HAT(NN,M)
      real :: HLHT(M,M), R(M,M), W0(M,M), W2(M,M)

      integer :: i, Tindex3D(M2(1),4), Sindex3D(M2(2),4) 
 
      ! (0) write date from observation time
      call date(tag,time)

      ! (1) compute & write H, HA, LHT, HLHT, R    
      call H_matrix(M2,M)                    ! H(M,N), use 1D locations to compute H,HA,AHATT, AHASS
      call L_matrix(M2,M)                    ! LHT(N,M), use 3D locations to get LHTT, LHSS 
      call R_matrix(M2,M)                    ! magnitude still needs to be determined
 
      ! (2) the second factor
      call readmatrix(HA,M,NN,'HA',2)        ! HA(M,NN)
      HAT = transpose(HA)                    ! HAT(NN,M)
      W0 = matmul(HA,HAT)                    ! HA(M,NN) HAT(NN,M) --> W0(M,M)

      if (localize) then      
         call readmatrix(HLHT,M,M,'HLHT',4)  ! HLHT(M,M)
         W0 = HLHT*W0
      endif
 
      call readmatrix(R,M,M,'R',1)

      !!========================================================================
      !!                    Check error variances                             !!
      open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')!!
      read(55) Tindex3D, Sindex3D                                             !!
      close(55)                                                               !!
                                                                              !!
      open(33,file='ensemble/check_error_vari'//tag//'.txt',form='formatted') !!
      do i=1,M                                                                !!
         if (i<=M2(1)) then                                                   !!
            write(33,'(I3,I3,F24.16,F24.16)') Tindex3D(i,4), Tindex3D(i,3),&  !! 
                                              R(i,i), W0(i,i)*alpha/(NN-1)    !!
         else                                                                 !!
            write(33,'(I3,I3,F24.16,F24.16)') Sindex3D(i-M2(1),4),&           !!
                         Sindex3D(i-M2(1),3), R(i,i), W0(i,i)*alpha/(NN-1)    !!
         endif                                                                !!
      enddo                                                                   !!
      close(33)                                                               !!
      !!========================================================================

      W0 = alpha*W0+(NN-1)*R                 ! W0(M,M)
      call inverse(W0,W2,M)                  ! W2(M,M)

      ! (3) the first factor       
      ! the upper part of W: WT(N/2,M)
      allocate(AHAT1(N/2,M2(1)))
      call readmatrix(AHAT1,N/2,M2(1),'AHAT1',5)
      if (localize) then
         allocate(LHTT(N/2,M2(1)))
         call readmatrix(LHTT,N/2,M2(1),'LHTT0',5,1)
         AHAT1 = AHAT1*LHTT
      endif
      allocate(AHAT2(N/2,M2(2)))
      call readmatrix(AHAT2,N/2,M2(2),'AHAT2',5)
      if (localize) then
         allocate(LHSS(N/2,M2(2)))
         call readmatrix(LHSS,N/2,M2(2),'LHSS0',5,1)
         AHAT2 = AHAT2*LHSS
      endif

      allocate(WT(N/2,M))
      WT(:,1:M2(1)) = AHAT1
      WT(:,M2(1)+1:M) = AHAT2
      deallocate(AHAT1,AHAT2)
      WT = matmul(WT,W2)
      WT = alpha*WT
      call writematrix(WT,N/2,M,'WT',2)
      deallocate(WT)

      ! the lower part of W: WS(N/2,M)
      allocate(AHAS1(N/2,M2(1)))
      call readmatrix(AHAS1,N/2,M2(1),'AHAS1',5)
      if (localize) then
         AHAS1 = AHAS1*LHTT
         deallocate(LHTT)
      endif
      allocate(AHAS2(N/2,M2(2)))
      call readmatrix(AHAS2,N/2,M2(2),'AHAS2',5)
      if (localize) then
         AHAS2 = AHAS2*LHSS
         deallocate(LHSS)
      endif

      allocate(WS(N/2,M))
      WS(:,1:M2(1)) = AHAS1
      WS(:,M2(1)+1:M) = AHAS2
      deallocate(AHAS1,AHAS2)
      WS = matmul(WS,W2)
      WS = alpha*WS
      call writematrix(WS,N/2,M,'WS',2)
      deallocate(WS)

      return
   end subroutine W_matrix

end module mod_matrix_W
