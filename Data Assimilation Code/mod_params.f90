module mod_params
   implicit none

   !********************************* Data Assimilation Step Options *********************************
   character (len=*), parameter :: output_pth = 'output/'      ! analysis file
   character (len=*), parameter :: input_pth  = 'input/'       ! background file
   character (len=*), parameter :: data_pth   = 'data/'        ! ensemble files
   character (len=*), parameter :: fname_var  = '_T.nc'        ! suffix of ensemble files

   logical, parameter :: step     =  .false.      ! .T. to construct ensemble   
   integer, parameter :: y_start  =    2012       ! first year of ensemble data pool
   integer, parameter :: y_end    =    2014       ! last year of ensemble data pool
   integer, parameter :: NN       =     121       ! size of ensemble (5 days per month from 2-year)
   integer, parameter :: NS       =     730       ! size of ensemble pool 
   integer, parameter :: DN       =       6       ! step interval to sample the ensemble pool 

   logical, parameter :: localize =   .true.      ! .T. for using localization
   logical, parameter :: loc_Lh   =   .true.      ! .T. for using horizontal localization
   logical, parameter :: loc_Lv   =   .true.      ! .T. for using vertical localization
   real, parameter    :: Lh       =     100.0     ! km, horizontal localization scale
   real, parameter    :: Lv       =     750.0     ! m, vertical localization scale
   real, parameter    :: alpha    =       0.001   ! scaling parameter of matrix B

   logical, parameter :: crt_bias =  .false.      ! .T. to correct model bias   
   real, parameter    :: rgamma   =       0.01    ! scaling parameter of model bias

   !************************************* Info about Argo Data ***************************************
   integer, parameter :: max_argo =       2       ! max number of argo to assimilate
   integer, parameter :: R_method =       2       ! 1 or 2 to select method for R
   ! R_method=1
   real, parameter    :: sigma_T1 =       1.0     ! instrument error: std of T (C)
   real, parameter    :: sigma_S1 =       0.05    ! instrument error: std of S (PSU)
   real, parameter    :: kappa_T  =       0.5     ! coef of representative error
   real, parameter    :: kappa_S  =       0.5     ! coef of representative error
   ! R_method=2
   real, parameter    :: sigma_T2 =       0.5     ! constant error
   real, parameter    :: sigma_S2 =       0.1     ! constant error

   !*********************************** Info on NEMO Output Data *************************************
   character (len=*), parameter :: REC_NAME = 'time_counter'
   character (len=*), parameter :: LVL_NAME = 'deptht'
   character (len=*), parameter :: LAT_NAME = 'nav_lat'
   character (len=*), parameter :: LON_NAME = 'nav_lon'
   character (len=*), parameter :: TMP_NAME = 'votemper'
   character (len=*), parameter :: SAL_NAME = 'vosaline'

   integer, parameter :: NDIMS =  4,  NRECS =   1              ! 4-D variables, 1 time record
   integer, parameter :: NLVLS = 50,  NLATS = 616, NLONS = 709 ! (k,j,i)=(50,616,709)

   !************************************* DA Subdomain Setting ***************************************
   integer, parameter :: sub_xy(4) = (/1, 106, 443, 616/)      ! start and end points in x and y 
   integer, parameter :: sub_x = 443, sub_y = 511              ! number of points in x-lon and y-lat
   integer, parameter :: N  = NLVLS*sub_x*sub_y*2              ! number of model grid points of T, S

end module mod_params
