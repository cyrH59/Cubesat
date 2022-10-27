function [n_estime] = time_synchro(K_estime,Np,Nsw,x,M,chirp)
    a=K_estime-1/2;
    b=K_estime+1/2;
    I=b-a;
    max_errors = 1;
    N_it = log2((b-a)*M/max_errors);
    for i =1:N_it
        if H_w(Np,Nsw,a,x,M,chirp) > H_w(Np,Nsw,b,x,M,chirp)
            b=b-I/2;
            n_estime = a*M;
        else
            a=a+I/2;
            n_estime = b*M;
        end
        I=I/2;
    end
end

     
function [H] = H_w(Np,Nsw,w,x,M,chirp) % Np : nombres de chirps up, Nsw : nombres de chirps de synchro, w : indice ou calculer la fonction
% x :signal
    nb_colonnes = Np+Nsw;
    if w<0
        x=[zeros(1,M),x]; % on rajoute des 0 devant si le préambule se situe dans le premier paquet de M chirps
        w=1+w;
    end
    temp=floor(length(x)/M); % Durée d'un chirp
    x=x(1:temp*M); % on redimensionne x pour le reshape
    
    sig_reshaped=reshape(x,[M,temp]); % on met en colonne les chirps
    x = sig_reshaped.*chirp'; % signal de-chirpé
    x=x(:);
    vect = zeros(1,nb_colonnes);
    for i =1:nb_colonnes
        vect(i) = max(abs(fft(x((i+w-1)*M+1:(i+w)*M)))); % calcul des max des fft des paquets de M chirps
    end
    H = sum(vect); % on somme tous les maxs trouvés dans le préambule
end