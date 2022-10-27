function [nu] = frac_CFO(y,Nc,M)

    nu = 0; 
    for p=0:Nc-2
        somme_droite = 0;
        for i=1:M 
            somme_droite = somme_droite + y(i,p+1)*conj(y(i,p+2));
        end
        nu=nu+angle(somme_droite)/(2*pi);
    end
    nu=nu/(Nc-1);
end

