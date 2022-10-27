clear;
close all;
clc

%% Paramètres
SF = 7 ;            %Nombre de bits/symbole   % Faire varier
M=2^SF;

Fse=10; % Facteur de sur-échantillonnage
B=125e3/2^(12-SF);            % Largeur de bande la plus commun pour transmission LoRa %% faire varier
Ts=M/B;            %Temps symbole
Ds = 1/Ts;         %Debit symbole
Te = Ts/M;        %Période d'échantillonnage
Nb_preambule_up = 4; % Preambule    % Faire varier
Nb_preambule_down=1; % SFD
N_sw = 2; % synchro word
val_sw = 1030; % valeur du mot de synchro
taille_preambule = Nb_preambule_down+Nb_preambule_up+N_sw;
time_upsampled = 0:Te/Fse:Ts-Te/Fse;                % base de temps sur laquelle les chirps sont générés
time = 0:Te:Ts-Te;
eb_n0_dB = -19+3*(12-SF):1:-6+3*(12-SF); % Liste des Eb/N0 en dB   % Faire varier
eb_n0 = 10.^(eb_n0_dB/10); % Liste des Eb/N0
DR_max = 280; % Hz/s
% time_upsampled = -Ts/2:Te/Fse:Ts/2-Te/Fse;
% time=-Ts/2:Te:Ts/2-Te;
chirp_up_upsampled= exp(1j*2*pi*fc(time_upsampled,0,B,Ts,0,M));
% test=fc(time_upsampled,0,B,Ts,0,M);
% test2 = 2*pi.*time_upsampled*B/Ts.*time_upsampled/2;
chirp_up= exp(1j*fc(time,0,B,Ts,0,M));
chirp_down= exp(-1j*fc(time,0,B,Ts,0,M));
chirp_down=conj(chirp_up);
chirp_down_upsampled = conj(chirp_up_upsampled);

Symbole_sync = [exp(1j*fc(time_upsampled,val_sw/B,B,Ts,val_sw,M)) exp(1j*fc(time_upsampled,val_sw/B,B,Ts,val_sw,M))]; % génération des chirps

%% Transmetteur
% chirp_up_upsampled= exp(1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);    % Chirp up sur échantillonné
% chirp_down_upsampled= exp(-1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);     %Chirp down sur échantillonné
% chirp_up= exp(1j*2*pi.*time*B/Ts.*time/2);    % Chirp up
% chirp_down= exp(-1j*2*pi.*time*B/Ts.*time/2);     %Chirp down
preambule=[repmat(chirp_up_upsampled,1,Nb_preambule_up),Symbole_sync,repmat(chirp_down_upsampled,1,Nb_preambule_down)]; % Préambule

%% Figures
fc_t=B/(2*Ts)*time;                     % fréquence du chirp brut
% chirp_up=exp(1i*2*pi*fc_t.*time);       % chirp montant (utilisé comme chirp brut)
% chirp_down=exp(-1i*2*pi*fc_t.*time);    % chirp descendant
% saveas(1,'erreur_quadratique_sf_7.png');
figure,spectrogram([chirp_up,chirp_up,chirp_down],hamming(64),60,1024,1/Te,'yaxis')
figure,spectrogram(preambule,hamming(640),600,1024,1/(Te/Fse),'centered','yaxis')