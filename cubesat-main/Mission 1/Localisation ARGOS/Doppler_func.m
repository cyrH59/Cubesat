function [fr]=Doppler_func(lambda,phi,h,ft,eloignement)
%fonction d'observation doppler de paramètres longitude lambda en radians, altitude h,
%latitude phi en radians et frequence de transmission du signal, eloignement vaut -1
%si le satellite s'éloigne du mobile et +1 s'ils se rapprochent

RE = 6378.137e3;                                  % Taille du demi grand axe en m
f = 1/298.257223563;                              % Aplatissement de l'ellipsoide
RP = RE*(1-f);                                    % Valeur du demi-petit axe 


vs=7e3;                                           % Vitesse du satellite en m/s
c=physconst('LightSpeed');                        % Célérité de la lumière en m/s
GE=RE+h; 
GP=RP+h;
theta = atan((GP/GE)*tan(phi));                   % Latitude paramétrique (ou réduite)

% Coordonnées cartésiennes de la balise à estimer.
x=GE*cos(theta)*cos(lambda); 
y=GE*cos(theta)*sin(lambda);
z=GP*sin(theta);

fr=ft*(1+1/c*(eloignement*vs*z/sqrt(x^2+y^2+z^2)));

end