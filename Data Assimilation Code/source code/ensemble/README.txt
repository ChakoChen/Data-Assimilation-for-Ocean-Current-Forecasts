Here is the list under my Argo data assimilation ensemble folder:

Amatrix.dta : matrix A(nxN), where n = ii*jj*kk*2 (ii,jj,kk are grid point numbers in x,y,z direction, 2 is because of T and S; N is the ensemble member)
ASmatrix.dta : (lower part of A matrix (n/2 * N))
ATmatrix.dta : (upper part of A matrix (n/2 * N))
coordinate.dta : (lon and lat for data assimilation domain)
ensemble_mean_sal.dta : (ensemble mean of salinity)
ensemble_mean_tmp.dta : (ensemble mean of temperature)
ensemble_sprd_sal.dta : (ensemble spread/std of salinity)
ensemble_sprd_tmp.dta : (ensemble spread/std of temperature)
model_sprd_sal.dta : same as ensemble spread of salinity
model_sprd_tmp.dta : same as ensemble spread of temperature
