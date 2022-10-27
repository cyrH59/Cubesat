clear;
close all;
clc

%% Param�tres
SF = 7 ;            %Nombre de bits/symbole
M=2^SF;

B=600e3;            % Largeur de bande
P= 14;              %Puissance du signal �mis (en Dbm)
Ts=M/B;            %Temps symbole
Ds = 1/Ts;         %Debit symbole
Te = Ts/M;        %P�riode d'�chantillonnage
Nb_preambule_up = 5;
Nb_preambule_down=2;
Nb_Chirp = 10;
SNR_dB = 40;           %Rapport signal sur bruit au niveau du r�cepteur
Nbbits = SF*Nb_Chirp;     %Nombre de bits g�n�r�s
time = -Ts/2:Te:Ts/2-Te;                % base de temps sur laquelle les chirps sont g�n�r�s

%% Transmetteur
sb = randi([0,1],1,Nbbits);
chirp_up= exp(1j*2*pi.*time*B/Ts.*time);    % Chirp up
chirp_down= exp(-1j*2*pi.*time*B/Ts.*time);     %Chirp down
sbMAT = reshape(sb,SF,length(sb)/SF);           %Matrice dont les colonnes sont des sous-sequences de SF bits

Sp = bit2int(sbMAT,SF,true);                    %Convertit en decimal les sequences de SF bits avec bit de poids fort � gauche (en haut de la colonne)

gammap = Sp/B;

preambule=[repmat(chirp_up,1,Nb_preambule_up), repmat(chirp_down,1,Nb_preambule_down)]; % Signal d'apprentissage (header loRa)
s=[];
for k=1:length(gammap)
    s = [s exp(1j*2*pi.*time.*fc(time,gammap(k),B,Ts))];
end
s=[preambule s];
%% Canal
h=1;

y=filter(h,1,s);

%% R�cepteur

Py = mean(abs(y).^2); % Puissance instantann�e du signal re�u
Pbruit = Py/10^(SNR_dB/10);
b = sqrt(Pbruit/2) * (randn(size(y)) + 1i*randn(size(y))); % vecteur de bruit AWG de variance Pbruit

x = y + b; % ajout du bruit au signal

temp=floor(length(x)/M); % Dur�e d'un chirp
x=x(1:temp*M); % on redimensionne x pour le reshape

sig_reshaped=reshape(x,[M,temp]); % on met en colonne les chirps
z=sig_reshaped.*chirp_up'; % multiplication par le chirp brut (dechirp)
[~, symbolesEstLoRa]=max(abs(fft(z, M, 1))); % argmax des FFT
symbolesEstLoRa = M - (symbolesEstLoRa-1); % symboles estim�s
bit_est = int2bit(symbolesEstLoRa(8:end),SF);%bits estim�s sans le pr�ambule
BER = mean(abs(bit_est(:)'-sb)); % calcul des erreurs
%% Figures


figure,
subplot 211
plot(abs(s)),title("Module de s")
subplot 212
plot(angle(s)),title("Phase de s")

figure,
subplot 211
plot(abs(fft(x))),title("Module de la fft du signal bruit�")
subplot 212
plot(angle(fft(x))),title("Phase de la fft du signal bruit�")
