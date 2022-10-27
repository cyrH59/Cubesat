clc
clear;
close all;

addpath("..\..\satellite_trajectory_link_budget")

%Simulation satellite
format long;

warning('off','all');

%% Constants
R=6378;         %Earth radius
d2r = pi/180;   %degrees to radians conversion
r2d = 180/pi;   %radians to degrees conversion
u =3998600.4415;  %Gravitational parameter


%% Inputs
H=1600 ;% satellite attitude (km)
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
 


%% Méthode des moindres carrés
%Estimation des coordonnées initiales
RE = 6378.137e3;                                  % Taille du demi grand axe en m
f = 1/298.257223563;                              % Aplatissement de l'ellipsoide
RP = RE*(1-f);  
Vs=7e3;                                           % Vitesse du satellite en m/s
c=physconst('LightSpeed');                        % Célérité de la lumière en m/s
hs=1500e3;                                        % Altitude du satellite en basse orbite
GE=RE+hs; 
GP=RP+hs;

ft0 = 868e6;                   % Fréquence d'emission par la plateforme
fr1 = ft0 + 3e3;               % Fréquence reçue au début du premier
fr2 = ft0 - 5e3;
R = 6371e3;                    % Rayon de la terre
etha = 1*d2r;                 % Angle entre l'axe joignant le sommet du cône et le centre de la sphère avec l'axe Z
phis = -87*d2r;                % Latitude au point sous-sommet du cone
lambdasat = S_long(1)*d2r;
phisat = S_lat(1)*d2r;
rov=FoV(Ecc(1),a, e, w, eps);   %rov :the radius of the Field of View in degrees.
[latc,longc] = scircle1(S_lat(1),S_long(1),rov);


[phi01,lambda01]=init_localisation(Vs,fr1,ft0,hs,R,etha,phis,lambdasat,phisat);
[phi02,lambda02]=init_localisation(Vs,fr2,ft0,hs,R,etha,phis,lambdasat,phisat);


phi01deg = phi01*r2d;
lambda01deg = lambda01*r2d;
phi02deg = phi02*r2d;
lambda02deg = lambda02*r2d;

figure()
plot([phi01deg phi02deg],[lambda01deg lambda02deg],'*')
xlabel("latitude"),ylabel("longitude"),title("Estimation positions initiales")
%geoplot([phisat*r2d],[lambdasat*r2d],'*')
%geolimits([45 62],[-149 -123])
%geobasemap streets
hold on
plot(latc,longc,'-')
legend("Pos init","Fov du satellite")

hold off


% Raffinement itératif (Méthode Gauss-Newton)
h0=0;                                                                    %Balise en mer par exemple
lambda0 = lambda01;
phi0 = phi01;
x0=[lambda0;phi0;h0;ft0];
mk= 4;                                                                                              % Nombre de mesures de fréquences sur un passage satellite (doit etre >=3 pour avoir assez d'equations)

% Test avec matrices

% n_pass_satellite = 4;
% %Z = [5000 1000 -5000 -8000;3000 2000 -4000 -9000;1000 500 -1000 -9500;3000 2500 -4000 -7500];       % Matrice contenant sur chaque ligne mk mesures d'effets Doppler sur un passage satellite
% 
% S_lat_rad = S_lat*d2r;
% S_long_rad = S_long*d2r;
% 
% z = [ft0+5000;ft0+1000;ft0-5000;ft0-8000];
% g=zeros(mk,1);
% 
% for k=1:mk
%     if(z(k)-ft0>=0)
%         g(k,1) = Doppler_func(lambda0,phi0,h0,ft0,1);
%     else
%         g(k,1) = Doppler_func(lambda0,phi0,h0,ft0,-1);
%     end
% end
% 
% sigma2 = 1;                                    % Variance du bruit
% R = sigma2*eye(mk);
% 
% J = zeros(mk,4);
% for k=1:mk
%     J(k,:) = Jacobien_H(lambda0,phi0,h0,ft0,S_long(10+(k-1)),S_lat(10 + (k-1)),H)';
% end
% 
% delta_x = inv(J'*inv(R)*J)*J'*inv(R)*(z-g);
% x1 = x0 + delta_x;


% Test sans matrices
z = [ft0+5000;ft0+1000;ft0-5000;ft0-8000];
x0=[lambda0 phi0 h0 ft0];

Xk_MAT = zeros(mk+1,4);
Xk_MAT(1,:) = x0;

for i=1:mk
    J= Jacobien_H(lambda0,phi0,h0,ft0,S_long(10+(i-1)),S_lat(10 + (i-1)),H)';
    sigma2 = 2;                                    % Variance du bruit
    R = sigma2*eye(mk);

    if(z(i)-ft0>=0)                                             % Effet doppler positif donc le satellite se rapproche de la balise
        g = Doppler_func(lambda0,phi0,h0,ft0,1);
    else
        g = Doppler_func(lambda0,phi0,h0,ft0,-1);
    end
    
    dxk0=inv(J'*inv(R)*J)*J'*inv(R)*(z(i)-g);              % calcul de la petite variation pour raffiner l'estimation des coord
    disp( "Jacobienne : " +inv(J'*inv(R)*J)*J'*inv(R))
    disp("g : "+ g )
    disp("z et doppler func :  " +(z(i)-g) )
    
    x1=x0+dxk0;

    Xk_MAT(i+1,:)=x1;
    lambda0 = x1(1);
    phi0 = x1(2);
    h0 = x1(3);
    ft0 =x1(4);
    x0=[lambda0 phi0 h0 ft0];
end

Xk_MAT(:,1:2) = Xk_MAT(:,1:2)*r2d;

figure()
plot(Xk_MAT(:,1),Xk_MAT(:,2),'*')
title("Evolution de la position au fil des itérations")
xlabel("Longitude (°)")

xlabel("Latitude (°)")


