function [lambda] = STO_esti(rcd,M,chirp,nu_est,Np)   
    for k=0:M-1
        for j=1:Np
            res(k+1,j) = sum((rcd(:,j).*chirp'.*exp(-1j*2*pi*nu_est*(0:M-1)/M).').*exp(-1j*2*pi*(0:M-1)*k/M).'); 
        end
    end
    res = res/sqrt(M);
    [~,ip]=max(abs(res));
    [ip1,R]=concave(res,ip,M);
    lambda_p = ip1-floor(ip1);
    lambda = mean(lambda_p);
end

