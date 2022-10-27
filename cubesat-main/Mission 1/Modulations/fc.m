function [f_c] = fc(t,gammap,B,Ts,Sp,M)
% fonction calculant les fréquences des symboles
    f_c=zeros(size(t));
%     for k=1:length(t)
%         if t(k)>=-Ts/2 && t(k)<-Ts/2+gammap
%             f_c(k)=(B/(2*Ts))*(t(k)-2*gammap)+B;
%         elseif t(k)>=-Ts/2+gammap && t(k)<=Ts/2
%             f_c(k)=(B/(2*Ts))*(t(k)-2*gammap);
%         end
%     end
    for k=1:length(t)
        if t(k) >=0 && t(k)<Ts-gammap
            f_c(k)=2*pi*M*((t(k)/(2*Ts))^2+(Sp/M-1/2)*t(k)/Ts);
        elseif t(k)>=Ts-gammap && t(k)<=Ts
            f_c(k)=2*pi*M*((t(k)/(2*Ts))^2+(Sp/M-3/2)*t(k)/Ts);
        end
    end
end

