clc
clear;
close all;
addpath("..\..\satellite_trajectory_link_budget")
format long;
warning('off','all');

%%% Estimation de l'évolution de l'effet Doppler en foction du temps pour
%%% à la reception depuis un site au sol et determination du Doppler rate

%% Localisation du site d'émission
Site_Lat=30;
Site_Long=30;

%% Constantes
R=6378;                                                                     % Rayon de la terre en km
u =3998600.4415;                                                            % Gravitational parameter
fT=2.4e9;                                                                   % frequence de la porteuse
Vs=7;                                                                       % Vitesse du sattelite en Km/s par rapport à la surface de la terre
c=299792.458;                                                               % Vitesse du la lumière en Km/s 

%% Parametres sur la trajectoire du satellite
H=500 ;                                                                     % satellite attitude (km)
a=H+R ;                                                                     % Semimajor axis in Km
e=0;                                                                        % Eccentricity 
i=90;                                                                       % Inclination
omega=90;                                                                   % Right ascension of the ascending node
w=90;                                                                       % Argument of perigee
theta=90;                                                                   % Initial True anomaly
eps=20;                                                                     % minimum elevation angle in degrees
UTC='08-sep-2020 17:46:16';                                                 % Satellite launch time
latmin=-90;
latmax=90;
T=(2*pi)*(sqrt((a^3)/u));                                                   %The Satellite period around the Earth in seconds

%% Parametres de la simulation
steps=100;                                                                  %Précision de la simulation 
dT=T/steps;                                                                 %Time step
N=1;                                                                        % number of turns around earth
T_f=N*T;                                                                    %24h
time = 0:dT:T_f/2-dT;

%% Simulation 
disp('The Simulator is running satrack.m function');
[S_lat, S_long, Ecc, E_time] = satrackFoV(a, e, i, omega, w, theta, UTC,time,T);


S_long=S_long+180;

%%



E = ElevationAngle2(S_long,S_lat,Site_Long,Site_Lat,H);
fR=fT*(1-Vs*cosd(E)/c);
EffetDoppler=fR-fT;
figure,
plot(time,EffetDoppler,"r");
xlabel('temps (s)')
ylabel('Décalage Doppler (hz)')
title("Décalage Doppler pour un site de latitude 30° et de longitude 30° lors d'une demi periode polaire")

figure,

%bordeaux
Site_Lat=44.8378;
Site_Long=-0.594;
E1 = ElevationAngle2(S_long,S_lat,Site_Long,Site_Lat,H);
fR=fT*(1-Vs*cosd(E1)/c);
EffetDoppler1=fR-fT;
Site_Lat=0;
Site_Long=0;
E2 = ElevationAngle2(S_long,S_lat,Site_Long,Site_Lat,H);
fR=fT*(1-Vs*cosd(E2)/c);
EffetDoppler2=fR-fT;
hold on
plot(time,EffetDoppler1);
plot(time,EffetDoppler);
plot(time,EffetDoppler2);
hold off
xlabel('temps (s)')
ylabel('Décalage Doppler (hz)')
legend('site à Bordeaux','site de latitude 30° et de longitude 30°','site de latitude 0° et de longitude 0°')
title("Décalage Doppler pour différent sites d'émission lors d'une demi periode polaire")


time = time(1:end-1);
figure,
plot(time,(EffetDoppler(2 :end)-EffetDoppler(1 :end-1))/dT,"r");
xlabel('temps (s)')
ylabel('Doppler rate (hz/s)')
title("Doppler rate pour un site de latitude 30° et de longitude 30° lors d'une demi periode polaire")

figure,
hold on
plot(time,(EffetDoppler1(2 :end)-EffetDoppler1(1 :end-1))/dT);
plot(time,(EffetDoppler(2 :end)-EffetDoppler(1 :end-1))/dT);
plot(time,(EffetDoppler2(2 :end)-EffetDoppler2(1 :end-1))/dT);
hold off
xlabel('temps (s)')
ylabel('Doppler rate (hz/s)')
legend('site à Bordeaux','site de latitude 30° et de longitude 30°','site de latitude 0° et de longitude 0°')
title("Doppler rate pour différent sites d'émission lors d'une demi periode polaire")

DureePaquet=0.01774;
VariationMaxDoppler=max(abs((EffetDoppler1(2 :end)-EffetDoppler1(1 :end-1))/dT))*DureePaquet



