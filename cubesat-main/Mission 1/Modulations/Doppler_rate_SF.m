clear;
close all;
clc

%% Paramètres
SF = 7:1:12 ;            %Nombre de bits/symbole   % Faire varier
Nb_preambule_up = 8; % Preambule    % Faire varier
Nb_preambule_down=1; % SFD
N_sw = 2; % synchro word
val_sw = 10; % valeur du mot de synchro
DR_max = 280; % Hz/s
erreur_quadratique = zeros(length(SF),13);
erreur_standard = zeros(length(SF),13);
var_boucle = 1E3;
for boucle=1:var_boucle
    Dr_simul = DR_max * unifrnd(0,1);
    %% Transmetteur

    %chirp_up_upsampled= exp(1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);    % Chirp up sur échantillonné
    %chirp_down_upsampled= exp(-1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);     %Chirp down sur échantillonné
    %chirp_up= exp(1j*2*pi.*time*B/Ts.*time/2);    % Chirp up
    %chirp_down= exp(-1j*2*pi.*time*B/Ts.*time/2);     %Chirp down

    for NpBoucle=1:length(SF)
        M=2^SF(NpBoucle);

        Fse=10; % Facteur de sur-échantillonnage
        B=125e3/2^(12-SF(NpBoucle));            % Largeur de bande la plus commun pour transmission LoRa %% faire varier
        Ts=M/B;            %Temps symbole
        Ds = 1/Ts;         %Debit symbole
        Te = Ts/M;        %Période d'échantillonnage

        taille_preambule = Nb_preambule_down+Nb_preambule_up+N_sw;
        time_upsampled = 0:Te/Fse:Ts-Te/Fse;                % base de temps sur laquelle les chirps sont générés
        time = 0:Te:Ts-Te;
        eb_n0_dB(NpBoucle,:) = -18+3*(12-SF(NpBoucle)):1:-6+3*(12-SF(NpBoucle)); % Liste des Eb/N0 en dB   % Faire varier
        eb_n0 = 10.^(eb_n0_dB(NpBoucle,:)/10); % Liste des Eb/N0

        chirp_up_upsampled= exp(1j*fc(time_upsampled,0,B,Ts,0,M));
        chirp_up= exp(1j*fc(time,0,B,Ts,0,M));
        chirp_down=conj(chirp_up);
        chirp_down_upsampled = conj(chirp_up_upsampled);

        Symbole_sync = [exp(1j*2*pi.*time_upsampled.*fc(time_upsampled,val_sw/B,B,Ts,val_sw,M)) exp(1j*2*pi.*time_upsampled.*fc(time_upsampled,val_sw/B,B,Ts,val_sw,M))]; % génération des chirps


        preambule=[repmat(chirp_up_upsampled,1,Nb_preambule_up),Symbole_sync,repmat(chirp_down_upsampled,1,Nb_preambule_down)]; % Préambule
        s=preambule;

        %% Canal
        h=1;

        y=filter(h,1,s);

        %% Récepteur
        for i=1:length(eb_n0_dB(NpBoucle,:))

            Py = mean(abs(y).^2); % Puissance instantanée du signal reçu
            Pbruit = Py/10^(eb_n0_dB(NpBoucle,i)/10); % Puissance du bruit
            b = sqrt(Pbruit/2) * (randn(size(y)) + 1i*randn(size(y))); % vecteur de bruit AWG de variance Pbruit

            x = y + b; %ajout du bruit au signal

            % Ajout du Doppler Rate
            t=((0:length(x)-1)*Te/Fse).^2;
            x=x.*exp(1j*pi*Dr_simul*t);
            %% Estimation du décalage temporel
            x2=x(1:Fse:end);% on travail en mode sous échantillonné pour tous les traitements
            %%
            DR_esti = doppler_rate_esti(x2,M,Nb_preambule_up,chirp_up,Ts,1); %estimation doppler rate

            erreur_quadratique(NpBoucle,i) =erreur_quadratique(NpBoucle,i)+ (Dr_simul-DR_esti)^2;
            erreur_standard(NpBoucle,i) = erreur_standard(NpBoucle,i)+abs(Dr_simul-DR_esti);

        end

    end
end

%% Figures

figure(1),semilogy(eb_n0_dB.',erreur_quadratique.'/var_boucle),grid on,title('Squared Error'),legend('SF=7','SF=8','SF=9','SF=10','SF=11','SF=12')
xlabel('$eb\_n0\_dB$','Interpreter','latex','fontsize',14),ylabel('$(\hat{D}_p-D_p)^2$','Interpreter','latex','fontsize',14)
figure(2),semilogy(eb_n0_dB.',erreur_standard.'/var_boucle),grid on,title('Standard Error'),legend('SF=7','SF=8','SF=9','SF=10','SF=11','SF=12')
xlabel('$eb\_n0\_dB$','Interpreter','latex','fontsize',14),ylabel('$ \left| \hat{D}_p-D_p\right| $','Interpreter','latex','fontsize',14)
saveas(1,'erreur_quadratique_tous_les_sf.png');
saveas(2,'erreur_standard_tous_les_sf.png');