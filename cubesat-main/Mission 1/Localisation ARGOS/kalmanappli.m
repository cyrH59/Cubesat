clc
close all
clear all

% Implementation filtre de Kalman étendu :

%% Initialisation :

T=1; %Periode d'échantillonnage en seconde
Timeduration=100*T;  % Duree totale
Time=0:T:Timeduration; % Temps
nstates = 6;         % Nombre d'état (Position (x,y,z) et Vitesse (vx,vy,vz)
nmeas = 3;           % Nombre de mesures
longorigine=-0.5; %On considère ces points comme l'origine du repère cartésien situé au centre de la balise
latorigine=44;
horigine=0;
% Positions initiales

px=0;
py=0;
pz=0;
% Vitesses initiales
vx = 7;
vy= 7;
vz= 0;

Nombreech=length(Time); %nombre de valeurs de time
init_pos = [px; py ; pz]; %  Position initiale
V = [vx; vy; vz]; % Vecteur vitesse de la balise
R=[9 0 0;0 1 0;0 0 1]; %matrice de covariance avec As Mean and variance of measured noise is Range(0,9), Azimuth(0,1), Elevation(0,1)

x(:,1) = [init_pos;V ]+[randn(3,1);16*randn(3,1)]; % Ajout d'un bruit gaussien à ce vecteur d'état
P0 = [9*eye(3,3) zeros(3,3); zeros(3,3) 16^2*eye(3,3)]; % Vecteur initial covariance


noise =sqrt(R)*randn(3, Nombreech); % Vecteur bruit contenant un bruit pour chaque coordonnées
xt(:,1) = [px; py; pz; vx; vy; vz]; %Valeur initial transmise considérée connue
ynoisy = zeros(3, Nombreech); % Calcul des positions
for k = 2:Nombreech
    xt(1,k) = xt(1,k-1)+T*V(1);
    xt(2,k) = xt(2,k-1)+T*V(2);
    xt(3,k) = xt(3,k-1)+T*V(3);

end

xt(:,1)=[px;py;pz;vx;vy;vz];
% calcul dans un nouveau repère
for k = 1:Nombreech
    ytrue(:,k) = [sqrt(xt(1,k)^2 + xt(2,k)^2 + xt(3,k)^2); ...
        atan2d(xt(2,k),xt(1,k)); ...
        atan2d(xt(3,k),(sqrt(xt(1,k)^2 +xt(2,k)^2)))]
    ynoisy(:,k) = ytrue(:,k) + noise(:,k);
end
%h(:,1)=[sqrt(x(1,1)^2 + x(2,1)^2 + x(3,1)^2); atan2d(x(2,1),x(1,1));atan2d(x(3,1),(sqrt(x(1,1)^2 +x(2,1)^2)))];
%test retour coordonnées polaire à longitude, latitude, hauteur :
wgs84 = wgs84Ellipsoid;
[lat,lon,hauteur] = aer2geodetic(ynoisy(2,41),ynoisy(3,41),ynoisy(1,41),latorigine,longorigine,horigine,wgs84)

xest = zeros(6,Nombreech); %Estimation du vecteur d'état contenant toutes les informations voulues

F=[1 0 0 T 0 0; 0 1 0 0 T 0;0 0 1 0 0 T; 0 0 0 1 0 0;0 0 0 0 1 0;0 0 0 0 0 1];  % Matrice de transition
h(:,1)=[201,45,54];
for k = 1:Nombreech
    % Prediction
    if k==1
        xest(:,1) = x(:,1);
        P = P0;
    else

        % Phase de prévision :
        x_pred = F*xest(:,k-1);
        P_pred = F*P*F';
        x=x_pred(1);
        y=x_pred(2);
        z=x_pred(3);
        % Passage en coordonnées polaires :
        y_est(:,k) = [sqrt(x_pred(1)^2 + x_pred(2)^2 + x_pred(3)^2); ...
            atan2d(x_pred(2),x_pred(1)); ...
            atan2d(x_pred(3),(sqrt(x_pred(1)^2 +x_pred(2)^2)))];
        %%% Matrice Jacobienne : 
        H=[x/(x^2 + y^2 + z^2)^(1/2),                        y/(x^2 + y^2 + z^2)^(1/2),                   z/(x^2 + y^2 + z^2)^(1/2), 0, 0, 0;
            -y/(x^2*(y^2/x^2 + 1)),                              1/(x*(y^2/x^2 + 1)),                                           0, 0, 0, 0;
            -(x*z)/((z^2/(x^2 + y^2 + z^2) + 1)*(x^2 + y^2 + z^2)^(3/2)), -(y*z)/((z^2/(x^2 + y^2 + z^2) + 1)*(x^2 + y^2 + z^2)^(3/2)), (1/(x^2 + y^2 + z^2)^(1/2) - z^2/(x^2 + y^2 + z^2)^(3/2))/(z^2/(x^2 + y^2 + z^2) + 1), 0, 0, 0];

        % Phase de correction
        S=(H*P_pred*H' + R)
        K = P_pred*H'*inv(S) % Calculate Kalman gain
        xest(:,k) = x_pred + K*(ynoisy(:,k) - y_est(:,k)); % Update state estimate
        P = (eye(nstates)-K*H)*P_pred; % Update covariance estimate
        h(:,k)=[sqrt(xest(1,k)^2 + xest(2,k)^2 + xest(3,k)^2); ...
            atan2d(xest(2,k),xest(1,k)); ...
            atan2d(xest(3,k),(sqrt(xest(1,k)^2 +xest(2,k)^2)))];
    end
end

[latest,longest,hauteurest] = aer2geodetic(h(2,:),h(3,:),h(1,:),latorigine,longorigine,horigine,wgs84)
[lattrue,longtrue,hauteurtrue] = aer2geodetic(ytrue(2,:),ytrue(3,:),ytrue(1,:),latorigine,longorigine,horigine,wgs84)

figure; 
plot(longest,latest,'*')
hold on 
plot(longtrue,lattrue, 'x');
title("Estimation de trajectoire à l'aide du Filtre de Kalman")
legend('Estimée','Vrai position','location','NorthWest')
