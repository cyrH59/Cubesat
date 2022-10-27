clc
clear all
close all

%% Implementation marches aléatoires :

% Paramètre de diffusion :
Dlambda=0.1;          
Dphi=0.1;

Vf=100;             % covariance du bruit de dynamique sur la fréquence d'émission (du aux variations de température)
Dt= 1000;           % temps depuis le dernier passage satellite en seconde
longorigine=-0.5;
latorigine=44;
vlamborig=5;        % vitesse selon m/s
vphiorig=5;         %vitesse en m/s
ft0= 868e6;         % fréquence d'émission de la balise
Q = [2*Dlambda*Dt 0 0; 0 2*Dphi*Dt 0; 0 0 Vf];          %matrice de corrélation du bruit
xo=[longorigine latorigine ft0];                        % vecteur d'état
xobis=[longorigine latorigine vlamborig vphiorig ft0];  % vecteur d'état contenant en plus les vitesses

% Marche aléatoire :

xest=zeros(3,10);               % positions à chaque passage satellite
xest(:,1)=xo';

for k=2:10
    xest(:,k)=xest(:,k-1)+sqrt(Q)*randn(3,1);
end

% Marche aléatoire correlée :

N=5;                    % Nombre de passages satellites
xestbis=zeros(5,N);     % positions à chaque passage satellite
xestbis(:,1)=xobis';
Qbis=[0 0 0 0 0; 0 0 0 0 0;0 0 2*Dlambda*Dt 0 0; 0 0 0 2*Dphi*Dt 0; 0 0 0 0 Vf];    %Matrice de covariance du bruit
M=[1 0 Dt 0 0; 0 1 0 Dt 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1];
for k=2:N
    xestbis(:,k)=M*xestbis(:,k-1)+sqrt(Qbis)*randn(5,1);
end

% Marche aléatoire biaisée :

de = 110e3;             % distance en longitude à l'équateur
Nthree=5;               % nombre de passage satellites
xestthree=zeros(3,Nthree);   % positions à chaque passage satellite
xestthree(:,1)=xo';
Qthree=[2*Dlambda*Dt 0 0; 0 2*Dphi*Dt 0; 0 0 Vf];   %Matrice de covariance du bruit
M=[Dt/de*cos(longorigine) 0; 0 Dt/de; 0 0];
alpha=0.3;

v=zeros(2,Nthree); %Ensemble des vecteurs vitesse
vinit1= [vlamborig vphiorig]'; %vecteur vitesse initiale pour k=0
v(:,1)=vinit1;

xestthree(:,2)=xestthree(:,1)+M*vinit1+sqrt(Qthree)*randn(3,1);

M=[Dt/de*cos(xestthree(1,2)) 0; 0 Dt/de; 0 0];
for k=2:Nthree
    vktild=(xestthree(1:2,k)-xestthree(1:2,k-1))/Dt;
    vtmp=alpha*vktild+(1-alpha)*v(:,k-1); %vecteur vitesse pour la prochaine itération
    v(:,k)=vtmp;
    xestthree(:,k+1)=xestthree(:,k)+M*v(:,k)+sqrt(Qthree)*randn(3,1);
    M=[Dt/de*cos(xestthree(1,k)) 0; 0 Dt/de; 0 0]; 
end


%% Plot :
figure;
plot(xestbis(1,:),xestbis(2,:),'r-')
title("Simulation trajectoire balise marche aléatoire corrélée")


figure;
plot(xest(1,:),xest(2,:),'r-')
title("Simulation trajectoire balise marche aléatoire")

figure;
plot(xestthree(1,:),xestthree(2,:),'r-')
title("Simulation trajectoire balise marche aléatoire biaisée")
