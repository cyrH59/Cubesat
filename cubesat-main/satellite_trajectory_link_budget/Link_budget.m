
                %%% Run code by section %%%
            %%%This code is based on Friiz Formula %%%

%% plot the emission distance depending on the emisison power for different satellite antenna gains.
clear all
clc
f=2.4*10^9 ; % freq de l'emission en Hz
c=299792.458*10^3 ; %Velocity of light (m/s)
lambda= c/f;
Pr= -82      ;    %Received power on earth in dBm
Ge=3:3:30;  %Emission gain en dBi
Gr=5    ;    %Reception gain in dB   Micro-strip "L" antenna
Pe=0:5:100; %emission power in dBm
figure,
for e=1:length(Ge)
    D=[];
    r=@(p,ge) lambda/(4*pi*10^((Pr-p-ge-Gr)/20))/10^3;
    for i=1:length(Pe)
        pw=10*log10(Pe(i)/0.001); % emission power in watts
        D=[D r(pw,Ge(e))];
    end
    plot(Pe,D)
    xlabel('Emission Power (W)')
    ylabel('Distance (Km)')
    title('F=2.4 GHz, G_r=5 dBm, P_r=-82 dBm')
    grid on,
    hold on
end


%% Plot the received power on earth depondind on the emmited power
clear all; clc, close all
f=2.4*10^9 ; % freq de l'emission en Hz
c=299792.458*10^3 ; %Velocity of light (m/s)
lambda= c/f;
H=600; % attitude in Km
Ge=18;
Gr=2.5;    %reception gain in dB   Micro-strip "L" antenna
Pe=[0:0.5:100]; % emission power in watts
Pr=@(pe,d) pe+Ge+Gr+20*log10(lambda/(4*pi*d*10^3)); %received power in dBm
figure,
for h=1:length(H)
    PR=[]; % puissance recu en dBm
    for e=1:length(Pe)
        pe_watt=Pe(e);
        pe_dBm=10*log10(pe_watt)+30;
        pr_dBm=Pr(pe_dBm,H(h));
        PR=[PR,pr_dBm];
    end
    plot(Pe,PR)
    ylabel('Received Power (dBm)')
    xlabel('Emission Power (W)')
    title(sprintf('F=%d Hz, Ge= %d dBi, Gr=%0.5f dBi, H=%d Km',f,Ge,Gr,H))
    grid on,
    hold on
end

%% Study satellite field of vue radius regarding to the received power on earth 
clear all;close all;clc
alpha=10; %angle d'ouverture de l'antenne en degrées
H=600; %Km
R=tand(alpha(end))*H; % field of vue radius (Km)
f=2.4*10^9 ; % emission frequency en Hz
c=299792.458*10^3 ; %Velocity of light (m/s)
lambda= c/f;
Ge=20;  %satellite antenna gain in dBi
Gr=3;    %reception antenna gain in dBi   Micro-strip "L" antenna
pe_watt=200; % emission power in watts
pe_dBm=10*log10(pe_watt)+30;
r=0:10:5*R*10^3; % rayon en metres (changer les bornes de l'intervalle comme vous convient)
Pr=@(d) pe_dBm+Ge+Gr+20*log10(lambda/(4*pi*d)); % puissance recue en dBm
pp=[];
for i=1:length(r)
    dis=r(i);
    dis=sqrt(dis^2+(H*10^3)^2);
    pp=[pp Pr(dis)];
end
figure,
plot(r*0.001,pp);
ylabel( 'Received Power(dBm)')
xlabel( 'radius(Km)')
title(sprintf('Ge=% dBi,Gr=%d dBi,H= %d Km,Pe= %d W',Ge,Gr,H,pe_watt))
grid on,

