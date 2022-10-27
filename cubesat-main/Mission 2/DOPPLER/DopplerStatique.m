clc;
clear ;
close all;

%% Paramètres

fT=2.4e9;                                                                   % frequence de la porteuse
Vs=7;                                                                       % Vitesse du sattelite en Km/s par rapport à la surface de la terre
c=299792.458;                                                               % Vitesse du la lumière en Km/s 
elevation=0:1:180;                                                          % Les angles de l'élévation en degré
DecalageMAX=175e3;                                                          % decalage maximum toléré

%% estimation cas statique

fR=fT*(1-Vs*cosd(elevation)/c);                                             % Frequence reçue
EffetDoppler=fR-fT;
PrecisionTx=(DecalageMAX)/2-abs(EffetDoppler);

%% figures
figure,
plot(elevation,abs(EffetDoppler)/1000,"r");
xlabel('Élévation (degrée)')
ylabel(' khz')
xlim([0 180])
yticks(0:5:60)
title('Décalage Doppler en module en fonction de l élévation');
figure,
plot(elevation,EffetDoppler/1000,"r");
xlabel('Élévation (degrée)')
ylabel('Décalage Doppler (khz)')
yticks(-60:10:60)
title('Décalage Doppler en fonction de l élévation "cas statique"');
figure,
plot(elevation,PrecisionTx/1000,"r");
xlabel('Élévation (degrée)')
ylabel('PrecisionTx (khz)')
title('Jeu de frequence accépté au niveau de l emetteur');
yticks(30:5:90)