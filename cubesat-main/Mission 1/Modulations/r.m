function R_w = r(z,w,M)
    w2=2*pi*(w-1)/M;
    R_w = abs(sum(z.'.*exp(-1j*(-1:length(z)-2)*w2)));
end

