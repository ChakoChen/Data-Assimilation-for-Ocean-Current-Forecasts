module mod_matrix_H
   use mod_params, only : N, NN 
   use mod_matrix_read
   use mod_matrix_write
   implicit none

   contains
   subroutine H_matrix(M2,M)
      implicit none
      integer, intent(in) :: M2(2), M
      real, allocatable :: H(:,:), A(:,:), HA(:,:), HAT(:,:)
      real, allocatable :: AT(:,:), AHATT(:,:), AS(:,:), AHASS(:,:)
      real, allocatable :: AHAT1(:,:), AHAT2(:,:), AHAS1(:,:), AHAS2(:,:)

      integer :: i, j
      integer :: Tindex1D(M2(1)), Sindex1D(M2(2))

      open(55,file='/home/chako/Argo/bias_nay/Index1D.dta',form='unformatted')
      read(55) Tindex1D, Sindex1D
      close(55)

      ! (1) compute matrix H
      allocate(H(M,N))
      H = 0.0
      do i=1,M2(1)
         H(i,Tindex1D(i)) = 1.0
      enddo
      do i=M2(1)+1,M
         H(i,N/2+Sindex1D(i-M2(1))) = 1.0
      enddo
 
      call writematrix(H,M,N,'H',1)
      deallocate(H) 

      ! (2) compute matrix HA
      allocate(A(N,NN), HA(M,NN))
      call readmatrix(A,N,NN,'A',1)
      do j=1,NN
         do i=1,M2(1)
            HA(i,j) = A(Tindex1D(i),j)
         enddo
      enddo
      do j=1,NN
         do i=M2(1)+1,M
            HA(i,j) = A(N/2+Sindex1D(i-M2(1)),j) 
         enddo
      enddo
      call writematrix(HA,M,NN,'HA',2)

      ! (3) compute matrix A(HAT): upper left and lower right
      allocate(HAT(NN,M))
      HAT = transpose(HA)
      deallocate(A,HA)

      allocate(AT(N/2,NN),AHAT1(N/2,M2(1)),AHAT2(N/2,M2(2)))
      call readmatrix(AT,N/2,NN,'AT',2)
      AHAT1 = matmul(AT,HAT(:,1:M2(1)))
      call writematrix(AHAT1,N/2,M2(1),'AHAT1',5)
      AHAT2 = matmul(AT,HAT(:,M2(1)+1:M))
      call writematrix(AHAT2,N/2,M2(2),'AHAT2',5)
      deallocate(AT,AHAT1,AHAT2)

      allocate(AS(N/2,NN),AHAS1(N/2,M2(1)),AHAS2(N/2,M2(2)))
      call readmatrix(AS,N/2,NN,'AS',2)
      AHAS1 = matmul(AS,HAT(:,1:M2(1)))
      call writematrix(AHAS1,N/2,M2(1),'AHAS1',5)
      AHAS2 = matmul(AS,HAT(:,M2(1)+1:M))
      call writematrix(AHAS2,N/2,M2(2),'AHAS2',5)
      deallocate(AS,AHAS1,AHAS2,HAT)

      return
   end subroutine H_matrix

end module mod_matrix_H
