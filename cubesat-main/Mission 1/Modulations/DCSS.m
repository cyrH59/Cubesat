clear;
close all;
clc

%% Paramètres
SF = 12 ;            %Nombre de bits/symbole
M=2^SF;

Fse=10; % Facteur de sur-échantillonnage
B=125e3;            % Largeur de bande la plus commun pour transmission LoRa
%B=600e3;            % Largeur de bande du sujet
P= 14;              %Puissance du signal émis (en Dbm)
Ts=M/B;            %Temps symbole
Ds = 1/Ts;         %Debit symbole
Te = Ts/M;        %Période d'échantillonnage
Nb_preambule_up = 7; % Preambule
Nb_preambule_down=1; % SFD
N_sw = 2; % synchro word
val_sw = 10; % valeur du mot de synchro
taille_preambule = Nb_preambule_down+Nb_preambule_up+N_sw;
Nb_Chirp = 10; % nombre de Chirp qu'on souhaite dans le signal
SNR_dB = 100;           %Rapport signal sur bruit au niveau du récepteur
Nbbits = SF*Nb_Chirp;     %Nombre de bits générés
time_upsampled = -Ts/2:Te/Fse:Ts/2-Te/Fse;                % base de temps sur laquelle les chirps sont générés
time = -Ts/2:Te:Ts/2-Te;
eb_n0_dB = -15:-5; % Liste des Eb/N0 en dB
eb_n0 = 10.^(eb_n0_dB/10); % Liste des Eb/N0
%% Transmetteur
sb = randi([0,1],1,Nbbits);     % génération des bits aléatoires
chirp_up_upsampled= exp(1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);    % Chirp up sur échantillonné
chirp_down_upsampled= exp(-1j*2*pi.*time_upsampled*B/Ts.*time_upsampled/2);     %Chirp down sur échantillonné
chirp_up= exp(1j*2*pi.*time*B/Ts.*time/2);    % Chirp up
chirp_down= exp(-1j*2*pi.*time*B/Ts.*time/2);     %Chirp down

sbMAT = reshape(sb,SF,length(sb)/SF);           %Matrice dont les colonnes sont des sous-sequences de SF bits

Sp = bit2int(sbMAT,SF,true);                    %Convertit en decimal les sequences de SF bits avec bit de poids fort à gauche (en haut de la colonne)
Dp = zeros(size(Sp));
% Modulation DCSS
for k=1:length(Sp)
    if k~=1
        Dp(k) = mod(Dp(k-1)+Sp(k),M);
    else
        Dp(k) = mod(Sp(k),M);
    end
end
Dp=[0,Dp];
gammap = Dp/B;

Symbole_sync = [exp(1j*2*pi.*time_upsampled.*fc(time_upsampled,val_sw/B,B,Ts)) exp(1j*2*pi.*time_upsampled.*fc(time_upsampled,val_sw/B,B,Ts))]; % génération des chirps

preambule=[repmat(chirp_up_upsampled,1,Nb_preambule_up),Symbole_sync,repmat(chirp_down_upsampled,1,Nb_preambule_down)]; % Préambule
s=[];
for k=1:length(gammap)
    s = [s exp(1j*2*pi.*time_upsampled.*fc(time_upsampled,gammap(k),B,Ts))]; % génération des chirps
end
s=[preambule s];
su=s;

%% Canal
h=1;

y=filter(h,1,su);

%% Décalage temporel
K = randi([2,10],1)
decalage_temporel = K*Fse*M+randi([-M/2,M/2-1],1); % génération d'un décalage aléatoire
y= [zeros(1,decalage_temporel),y]; % décalage du signal : on rajoute des 0 devant
%deca = [exp(1j*2*pi.*time_upsampled(1:decalage_temporel).*fc(time_upsampled(1:decalage_temporel),0,B,Ts))]; % génération des chirps
%y=[deca,y];
%% Récepteur
for i = 1:length(eb_n0)
    error_cnt=0;
    bit_cnt=0;
    while error_cnt < 100000
        Py = mean(abs(y).^2); % Puissance instantanée du signal reçu
        %Pbruit = Py/10^(SNR_dB/10); % Puissance du bruit
        Pbruit = Py/10^(eb_n0_dB(i)/10); % Puissance du bruit
        b = sqrt(Pbruit/2) * (randn(size(y)) + 1i*randn(size(y))); % vecteur de bruit AWG de variance Pbruit

        x = y + b; %ajout du bruit au signal

        % Ajout du Doppler Rate
        Cr=280; % valeur du Doppler Rate en Hz/s
        t=((0:length(x)-1)*Te/Fse).^2;
        x=x.*exp(1j*pi*Cr*t);

        %2/(Ts^2)*(test3(2)-test3(1))
        %% Estimation du décalage temporel
        x2=x;
        x=x(1:Fse:end);% on travail en mode sous échantillonné pour tous les traitements
        figure,plot(abs(fft(x(1:M).*chirp_down)))
        % Utilisation de la fonction dichotomique de Mr Ben Temim
        %         for k=1:7
        %             [pos] = recherche_dichotomique((test2(k)-2)*2*pi/M, test2(k)*2*pi/M, 1e-5, sig_Mat_Detect2(:,k));
        %             res(k) = pos*M/(2*pi)
        %         end
        % Détection du préambule
        K_estime = preambule_detect(chirp_up,Nb_preambule_up,N_sw,x,M,1); % estimation du décalage temporel
        K_estime;
        % Estimation du décalage temporel
        synchro_temporelle= time_synchro(K_estime,Nb_preambule_up,N_sw,x,M,chirp_up); % synchronisation temporelle
        (decalage_temporel/10-synchro_temporelle)/M;
        index_max=binary_search(x,K_estime,M,Nb_preambule_up,1,SF,chirp_up);
        (decalage_temporel/10-index_max)/M;

        %%
        DR_esti = doppler_rate_esti(x(synchro_temporelle:end),M,Nb_preambule_up,chirp_up,Ts); %estimation doppler rate
        x=x(synchro_temporelle:end);
        temp=floor(length(x)/M); % Durée d'un chirp
        x=x(1:temp*M); % on redimensionne x pour le reshape

        sig_reshaped=reshape(x,[M,temp]); % on met en colonne les chirps
        [~,L]=size(sig_reshaped);
        for j=1:Nb_preambule_up %on compense le dr que sur les up chirps du preambule
            rdc(:,j) = sig_reshaped(:,j).*exp(-1j*pi*DR_esti*Ts^2*(0:M-1).^2).'; % Dr compensation
        end
        %nu_est = frac_CFO(rdc,Nb_preambule_up,M); % cfo estimation
        %lambda_est = STO_esti(rdc,M,chirp_up,nu_est,Nb_preambule_up); % sto estimation
        % Compensation du cfo, sto et dr dans le payload
        %         valeur_sous_ech = round(lambda_est*Fse);
        %         signal_final = x2(synchro_temporelle+1:Fse:end); % sto compensation
        signal_final = x.*exp(-1j*pi*DR_esti*Ts^2*(0:length(x)-1).^2);
        sig_reshaped=reshape(signal_final,[M,temp]); % on met en colonne les chirps
        z=sig_reshaped.*chirp_up'; % multiplication par le chirp brut conjugué

        [max_fft, symbolesEstLoRa]=max(abs(fft(z))); % argmax des FFT
        symbolesEstLoRa = M-(symbolesEstLoRa(taille_preambule:end)-1) ;% symboles estimés sans le préambule

        % Amélio concavité sert que pour estimer le décalage doppler.
        %[symbole,maxi]= concave(z(:,8:end),symbolesEstLoRa,M); % amélioration de la localisation des max
        for k=1:length(symbolesEstLoRa)-1
            symboleEst(k) =mod(symbolesEstLoRa(k+1)-symbolesEstLoRa(k),M); % calcul des symboles Sp
            %new_symb_est(k)=round(mod(symbole(k+1)-symbole(k),M)); % calcul des symboles Sp
        end
        if length(symboleEst)>length(Sp)
            symboleEst=symboleEst(length(symboleEst)-length(Sp)+1:end);
        end
        bit_est = int2bit(symboleEst,SF);%bits estimés sans le préambule méthode "classique"
        %bit_est2 = int2bit(new_symb_est,SF);%bits estimés sans le préambule méthode algo concavité
        BER = mean(abs(sb-bit_est(:).')); % BER avec méthode "classique" (argmax des fft)
        error_cnt=error_cnt+sum(sb~=bit_est(:).');
        bit_cnt=bit_cnt + length(sb); %attention au bit_cnt
    end
    TEB(i) = error_cnt/bit_cnt;
end
%BER2=mean(abs(sb-bit_est2(:)')); % BER avec l'algo de concavité

%% Figures

figure,
semilogy(eb_n0_dB,TEB);
grid()

figure,
subplot 211
plot(abs(s)),title("Module de s")
subplot 212
plot(angle(s)),title("Phase de s")

figure,
subplot 211
plot(abs(fft(x))),title("Module de la fft du signal bruité")
subplot 212
plot(angle(fft(x))),title("Phase de la fft du signal bruité")


