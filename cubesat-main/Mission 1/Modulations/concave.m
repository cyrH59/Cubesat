function [symb,Rw] = concave(z,Dp_estimes,M) % sert à trouver le décalage en fréquence
% fonction qui réalise l'algorithme de concavité pour réaliser de manière
% précise la localisation des argmax
    a_tab = Dp_estimes -1; % 
    b_tab = Dp_estimes +1 ;% Tableau des intervalles à étudier
    
    epsilon = 1E-2;
    p=log2((b_tab(1)-a_tab(1))/epsilon)+1; % 
    N=2^p; % Nombres de points sur lequels on travaille
    
    for k=1:length(a_tab) % on boucle sur les intervalles
        for i=1:p % on boucle sur chaque puissance de 2
            mid1=a_tab(k)+(b_tab(k)-a_tab(k))/2; % calcul du milieu 1
            mid2=mid1 + 1/N; % calcul du second milieu
            R_w = [r(z(:,k),a_tab(k),M),r(z(:,k),mid1,M),r(z(:,k),mid2,M),r(z(:,k),b_tab(k),M)]; % calcul de la fonction r_w sur les 4 points intéressants
            [~, indice] = max(R_w); % on regarde le max
            % choix du nouvel intervalle d'étude
            if indice <=2 
                b_tab(k)=mid1;
            else
                a_tab(k)=mid2;
            end
        end
        [Rw(k),sym(k)] = max([r(z(:,k),a_tab(k),M),r(z(:,k),b_tab(k),M)]); % on finit par prendre le max de r_w pour les deux bornes restantes
        if sym(k)==1 % choix de l'indice pour lequel le max est atteint
            symb(k)=a_tab(k);
        else
            symb(k)=b_tab(k);
        end
    end
end

function R_w = r(z,w,M)
    w2=2*pi*w/M;
    R_w = abs(sum((z.').*exp(-1j*(0:length(z)-1)*w2)));
end