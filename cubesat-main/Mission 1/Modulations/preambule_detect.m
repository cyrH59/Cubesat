function [K_est] = preambule_detect(chirp,Np,Nsw,sig,M,Fse)
    %detection du preambule
    
    temp = floor(length(sig)/(M*Fse)); %durée d'un chirp
    sig = sig(1:M*Fse*temp); % on coupe notre signal pour pouvoir le mettre en mode matrice (un chirp = une colonne)
    sig_Mat = reshape(sig,M*Fse,temp); % on transforme la matrice pour avoir des chirps en colonnes
    [~,L]=size(sig_Mat);
    for i=1:L
        sig_Mat_Detect(:,i)=sig_Mat(:,i).*chirp'; % On multiplie chaque colonne par le chirp brut conjugué
        test(:,i)=sig_Mat(:,i).*chirp.';
    end
    
    z = fft(sig_Mat_Detect); % calcul de la fft de chaque colonne
    
    for k=1:temp-1
        moy_fft(:,k) = (abs(z(:,k))+abs(z(:,k+1)))/2; %moyenne des fft sur 2 blocs consécutifs
    end

    [~,symb] = max(moy_fft); % calcul du argmax des ffts moyennées
    symbole = M-(symb-1); % calcul des symboles
    compteur=1; % compteur pour savoir combien de max valables on a détecté
    last=0; % variable pour savoir à quel indice on termine la boucle
    start_ind=0;
    for i=2:length(symbole)
        if symbole(i)-2<symbole(i-1) && symbole(i)+2>symbole(i-1) % on regarde si 2 max consécutifs ont la même abscisse
            compteur = compteur +1;
            last = i;
            if compteur >=Np/2
                start_ind = last - compteur+1; % on note l'indice du premier max consécutif
                break;
            end
        else % si 2 max consécutifs n'ont pas la même abscisse on reprend tout de 0
            compteur = 1;
            last = 0;
        end
    end
    sfd_locate = start_ind+Np+Nsw; % indice du symbole sfd
    sig_sfd = sig_Mat(:,start_ind:sfd_locate+3).*chirp.'; % on applique des up chirps la ou doit se situer notre sfd
    [maxval,~] = max(abs(fft(sig_sfd))); % calcul de l'approx du décalage temporel 
    [~,T_section_location] = max(maxval); 
    K_est =start_ind+ T_section_location-(sfd_locate+3-start_ind)+1;
    %K_est = start_ind;
end

