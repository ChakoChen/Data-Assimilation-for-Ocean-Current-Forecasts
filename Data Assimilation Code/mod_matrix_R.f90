module mod_matrix_R
   use mod_params, only : R_method, sigma_T1, sigma_S1, sigma_T2, Sigma_S2, kappa_T, kappa_S, sub_x, sub_y, NLVLS
   use mod_matrix_write
   implicit none

   contains
   subroutine R_matrix(M2,M)
      implicit none
      integer, intent (in) :: M2(2), M
      real, allocatable    :: R(:,:)
      integer :: i, j

      real   :: RT(NLVLS), RS(NLVLS)
      real    :: T_std(sub_x,sub_y,NLVLS), S_std(sub_x,sub_y,NLVLS)
      integer :: Tindex3D(M2(1),4), Sindex3D(M2(2),4)

      allocate(R(M,M))

      select case (R_method)

         ! I: R = const. + (factor*model_std)**2
         case(1)   
            open(unit=12,file='ensemble/model_sprd_tmp.dta',form='unformatted')
            read(12) T_std
            close(12)

            open(unit=22,file='ensemble/model_sprd_sal.dta',form='unformatted')
            read(22) S_std
            close(22)

            open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')
            read(55) Tindex3D, Sindex3D
            close(55)

            do j = 1,M
               do i = 1,M
                  if (i==j.and.i<=M2(1)) then
                     R(i,j) = sigma_T1**2 + (kappa_T*&
                              T_std(Tindex3D(i,1),Tindex3D(i,2),Tindex3D(i,3)))**2
                  elseif (i==j.and.i>M2(1)) then
                     R(i,j) = sigma_S1**2 + (kappa_S*&
                              S_std(Sindex3D(i-M2(1),1),Sindex3D(i-M2(1),2),Sindex3D(i-M2(1),3)))**2
                  else
                     R(i,j) = 0.0
                  endif
               enddo
            enddo

         ! II: R is constant 
         case(2)
            do j = 1,M
               do i = 1,M
                  if (i==j.and.i<=M2(1)) then
                     R(i,j) = sigma_T2**2
                  elseif (i==j.and.i>M2(1)) then
                     R(i,j) = sigma_S2**2
                  else
                     R(i,j) = 0.0
                  endif
               enddo
            enddo

         ! III: R is proportional to observation variance
         case(3)
            open(55,file='glider/Rmatrix.dta',form='unformatted',access='stream')
            read(55) RT, RS
            close(55)

            open(55,file='/home/chako/Argo/bias_nay/Index3D.dta',form='unformatted')
            read(55) Tindex3D, Sindex3D
            close(55)

            do j = 1,M
               do i = 1,M
                  if (i==j.and.i<=M2(1)) then
                     R(i,j) = RT(Tindex3D(i,3))/200.0
                  elseif (i==j.and.i>M2(1)) then
                     R(i,j) = RS(Sindex3D(i-M2(1),3))/2000.0 
                  else
                     R(i,j) = 0.0
                  endif
               enddo
            enddo
      end select

      call writematrix(R,M,M,'R',1)

      return
   end subroutine R_matrix

end module mod_matrix_R
