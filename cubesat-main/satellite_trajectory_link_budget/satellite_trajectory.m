clear;
clc;
close all;

format long;

warning('off','all');



%% Constants
R=6378;         %Earth radius
d2r = pi/180;   %degrees to radians conversion
r2d = 180/pi;   %radians to degrees conversion
u =3998600.4415;  %Gravitational parameter


%% Inputs
H=550 ;% satellite attitude (km)
a=H+R ;       %Semimajor axis in Km
e=0;          %Eccentricity 0.4
i=90;           %Inclination
omega=90;       %Right ascension of the ascending node
w=90;          %Argument of perigee
theta=90;      %Initial True anomaly
eps=20;         %minimum elevation angle in degrees
UTC='08-sep-2020 17:46:16'; %Satellite launch time
latmin=-90;%-90;
latmax=90;%90;

T=(2*pi)*(sqrt((a^3)/u)); %The Satellite period around the Earth in seconds
dT=T/20; %Time step
N=1; % number of turns around earth
T_f=N*T;
time = 0:dT:T_f-dT;

%% Output


%Satellite Ground Track
disp('The Simulator is running satrack.m function');
[S_lat, S_long, Ecc, E_time] = satrackFoV(a, e, i, omega, w, theta, UTC,time,T);

%% Display
%World map
disp('The Simulator is plotting the Worldmap');
worldmap world
load coastlines
[latcells, loncells] = polysplit(coastlat, coastlon);
plotm(coastlat, coastlon, 'green')
title(sprintf("Satellite trajectory, Simulation Time: %d T",N))
hold on

disp('The Simulator is drawing Satellite trajectory on the Worldmap');
for k = 1:length(S_lat)
    if S_lat(k)>latmin && S_lat(k)<latmax
        plotm(S_lat(k),S_long(k),'rs');
    end
end

hold on





disp('The Simulator is drawing the Field of View along Satellite trajectory and stores its lat/long coordinates in LATC/LONGC matrices ');

for t=1:length(Ecc)
    if S_lat(t)>latmin && S_lat(t)<latmax
                
        rov=FoV(Ecc(t),a, e, w, eps);
        [latc,longc] = scircle1(S_lat(t),S_long(t),rov);
        h2=plotm(latc,longc,'b-');

    end
end
hold off;



