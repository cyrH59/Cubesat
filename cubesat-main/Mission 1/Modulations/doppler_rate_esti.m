function [cd_estime] = doppler_rate_esti(x,M,Np,chirp,T,Fse)
    %fonction permettant d'estimer le doppler rate
    
    temp=floor(length(x)/(M*Fse)); % Durée d'un chirp
    x=x(1:temp*M*Fse); % on redimensionne x pour le reshape
    
    Mat=reshape(x,[M*Fse,temp]); % on met en colonne les chirps
    for i=1:Np
        Mat_Detect(:,i)=Mat(:,i).*chirp'; % On multiplie chaque colonne par le chirp brut conjugué
    end
    [~,test_ip1]=max(abs(fft(Mat_Detect)));
    % Utilisation de la fonction dichotomique de Mr Ben Temim
%     for k=1:Np
%         [pos] = recherche_dichotomique((test_ip1(k)-2)*2*pi/M, test_ip1(k)*2*pi/M, 1e-5, Mat_Detect(:,k));
%         res(k) = pos*M/(2*pi);
%     end
    [ip,~] = concave(Mat_Detect,test_ip1-1,M); % on utilise l'algo de concavité pour améliorer la valeur de positionnement des maxs
    %plot(ip,values,'x')
    ip;
    %ip=res;
    cd_estime=0;
    for p=1:Np-1 
        somme_droite = 0;
        for l=p+1:Np
               somme_droite = somme_droite+1/(T^2)*((ip(l)-ip(p)))/((l-p));
        end
        cd_estime=cd_estime+somme_droite/(Np-p);
    end
    cd_estime = cd_estime/(Np-1);
    %cd_estime2 = (ip(end)-ip(1))/(Np*T^2); % calcul du DR entre la premiere
    %et la derniere valeur du preambule
end