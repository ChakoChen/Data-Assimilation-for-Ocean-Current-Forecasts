clear; clc; 

ii = 443; jj = 511; kk = 50; % points in x (longitude), y (latitude), and z (depth) directions.

%% open coordinate file for DA domain
cd /home/c354chen/Documents/Research/DA_NEMO/DA_Argo
load depth.txt
fid = fopen('coordinate.dta','r','s');
bogus = fread(fid,1,'int32');
lons = fread(fid,[ii jj],'real*4','s');
lats = fread(fid,[ii jj],'real*4','s');
fclose(fid);

%% read background or analysis 
fname = 'background.dta';  % fname = 'analysis.dta';
fid = fopen(fname,'r','s');
bogus = fread(fid,1,'int32');
T = fread(fid,[ii*jj*kk],'real*4','s'); % temperature
S = fread(fid,[ii*jj*kk],'real*4','s'); % salinity
fclose(fid);

T = reshape(T,ii,jj,kk); T(T==0) = nan;
S = reshape(S,ii,jj,kk); S(S==0) = nan;
