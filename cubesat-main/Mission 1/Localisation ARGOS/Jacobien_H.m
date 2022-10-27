function [J_H]=Jacobien_H(lambda,phi,h,ft,lambdas,phis,hs)
%Jacobienne de la fonction d'observation Doppler H
% lambda: longitude en radians, phi : latitude en radians, h: altitude, ft : frequence de
% transmission,  lambdas : long du sat (à l'instant de mesure de l'effet doppler) , phis : latitude du sat , hs: altitude du sat

tau = 120e-3;                                       % durée d'une mesure
RE = 6378.137e3;                                  % Taille du demi grand axe en m
f = 1/298.257223563;                              % Aplatissement de l'ellipsoide
RP = RE*(1-f);                                    % Valeur du demi-petit axe 
c=physconst('LightSpeed');                        % Célérité de la lumière en m/s

%% Coordonnées cartésiennes :
GE=RE+h; 
GP=RP+h;
theta = atan((GP/GE)*tan(phi));                   % Latitude paramétrique (ou réduite)

x=GE*cos(theta)*cos(lambda); 
y=GE*cos(theta)*sin(lambda);
z=GP*sin(theta);


%%  coordonnées cartesiennes satellite :
GEs=RE+hs;
GPs=RP+hs;
thetas = atan((GPs/GEs)*tan(phis));

xs=GEs*cos(thetas)*cos(lambdas); 
ys=GEs*cos(thetas)*sin(lambdas);
zs=GPs*sin(thetas);
vs=7e3;                         %vitesse du satellite

zsf = zs + vs*tau;              %coordonnée selon z du satellite en fin de comptage
xsf = xs;                       %coordonnées en x et y sont inchangées puisque le satellite ne bouge que selon z
ysf = ys;
disp("zs : " +zs)
disp("zsf :"+ zsf)


Rf = sqrt((xsf-x)^2 + (ysf-y)^2 + (zsf -z)^2);  %distance satellite-balise en fin de comptage
Rd = sqrt((xs-x)^2 + (ys-y)^2 + (zs-z)^2);   %distance satellite-balise en début de comptage

vr = abs((Rf-Rd)/tau);                          % approximation de la vitesse radiale du satellite
disp("vr :"+ vr)

%% Calcul des differentes derivés
dH_dxyz = (ft/c*tau)*[((x-xsf)/Rf-(x-xs)/Rd) ((y-ysf)/Rf-(y-ys)/Rd) ((z-zsf)/Rf-(z-zs)/Rd)];

dH_dft = 1- vr/c;

dtheta_dphi = (GP/GE)/((1-GP^2/GE^2)*cos(phi)^2+(GP^2)/(GE^2));

dxyz_dlambdaphih = [-GE*cos(theta)*sin(lambda) -GE*sin(theta)*cos(lambda)*dtheta_dphi cos(theta)*sin(lambda);GE*cos(theta)*cos(lambda) -GE*sin(theta)*sin(lambda)*dtheta_dphi cos(theta)*sin(lambda);0 GP*cos(theta)*dtheta_dphi sin(theta)];

%% Jacobienne finale : 
J_H = [dH_dxyz*dxyz_dlambdaphih dH_dft];


end
