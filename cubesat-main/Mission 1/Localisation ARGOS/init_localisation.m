function [phi,lambda]=init_localisation(vs,fr,ft,hs,R,etha,phis,lambdasat,phisat)
% Fonction calculant l'intersection cone-sphere en cartésien et en
% géographique (A revoir)
%Entrées : vs :vitesse du satellite
%          fr :fréquence reçue au niveau du satellite
%          ft :fréquence transmise par la balise
%          hs : altitude du satellite 
%          R: rayon de la sphère (terre dans notre cas)
%          etha : angle entre l'axe joignant le sommet du cône et le centre
%          de la sphère avec l'axe de revolution du cône (dans notre cas,
%          c'est le vecteur vitesse du satellite)
%          phis : latitude au point sous-sommet du cone
%          lambdasat : longitude du sommet du cone (celle du satellite dans
%          notre cas)
%          phisat : latitude du satellite

%Sorties:  phi : latitude du point d'intersection (balise)
%          lambda : longitude du point d'intersection (balise)

%thèse utilisée : https://journals.ametsoc.org/view/journals/apme/10/3/1520-0450_1971_010_0607_tioaca_2_0_co_2.xml

c= physconst('Lightspeed'); %célérité de la lumière
a = c/vs*(fr/ft-1);
theta = atan(sqrt(1/a^2-1));                    % angle entre la génératrice et l'axe de révolution du cône
alpha = pi - atan(tan(lambdasat)/sin(phisat));  % azimuth (angle) du Nord vers l'axe du cone = angle entre le plan vertical contenant le satellite et le plan méridien

% Calcul des deux cas limites de Z2 notés Z2_0 et Z2_L
Z2_01 = hs*sin(theta)^2 + sqrt(R^2- hs^2*sin(theta)^2)*cos(theta);
Z2_02 = hs*sin(theta)^2 - sqrt(R^2- hs^2*sin(theta)^2)*cos(theta);

% disp("Z2_01 : "+ Z2_01)
% disp("Z2_02 : " + Z2_02)

if(Z2_01 >=0 && Z2_02 <0)       % sens physique (la coordonnée doit être >=0)
    Z2_0 = Z2_01;
elseif(Z2_02 >=0 && Z2_01 <0)
    Z2_0 = Z2_02;
elseif(Z2_01 >=0 && Z2_02 >=0)
    Z2_0 = Z2_01;
end

val_racine1 = R^2 - hs^2*sin(etha+theta)^2;         % gère les cas pour que cela soit positif sous la racine                 
val_racine2 = R^2 - hs^2*sin(etha-theta)^2;
% disp(val_racine1)
% disp(val_racine2)

if(val_racine1 >=0 && val_racine2 <0)                           
    Z2_L = hs*sin(etha+theta)^2 + sqrt(val_racine1)*cos(etha+theta);
elseif(val_racine2 >=0 && val_racine1 <0)
    Z2_L = hs*sin(etha-theta)^2 + sqrt(val_racine2)*cos(etha-theta);
elseif(val_racine1 >=0 && val_racine2>=0)
    Z2_L = hs*sin(etha+theta)^2 + sqrt(val_racine1)*cos(etha+theta);
end

% disp("Z2_0 : " +Z2_0)
% disp("Z2_L : " +Z2_L)

Z2 =Z2_L;

X21 = (1/sin(etha))*((Z2-hs)*cos(etha) + sqrt(hs^2 + R^2 -2*hs*Z2)*cos(theta));
X22 = (1/sin(etha))*((Z2-hs)*cos(etha) - sqrt(hs^2 + R^2 -2*hs*Z2)*cos(theta));
% disp("X21 : " +X21)
% disp("X22: " +X22)

if(X21<0 && X22>=0)         % sens physique (la coordonnée doit être >=0)
    X2 = X22;
elseif(X21>=0 && X22<0)
    X2= X21;
elseif(X21>=0 && X22>=0)
    X2= X21;
else
    X2 = abs(X21);
end

Y2 = sqrt(abs(R^2 -X2^2 -Z2^2));

% Rotation autour de l'axe Z2 d'un angle alpha
U= Y2*sin(alpha) +X2*cos(alpha);
V= Y2*cos(alpha) -X2*sin(alpha);
W=Z2;

% Rotation autour de l'axe V d'un angle 90°-phis
U1 = U.*sin(phis) -W.*cos(phis);
V1 = V;
W1= U.*cos(phis) +W.*sin(phis);

if(W1/R >=-1 && W1/R<=1)
    phi = asin(W1./R);
end

lambda= asin(V1./sqrt(U1.^2 +V1.^2));
lambda = lambda + lambdasat;

end



