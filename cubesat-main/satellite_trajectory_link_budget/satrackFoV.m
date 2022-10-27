%% Description

%This function produces a list of latitude/longitude coordinates, Eccentric anomaly values and 
%Satellite time passes over locations describing the Satellite orbit.
 
%% Inputs: 

    % a     :Semimajor axis
    % e     :Eccentricity
    % i     :Inclination
    % omega :Right ascension of the ascending node
    % w     :Argument of perigee
    % theta :Initial True anomaly
    % UTC    :Initial Epoch 
    
%% Outputs: 

    %S_lat  :The latitude coordinates describing the orbit in degrees.
    %S_long :The longitude oordinates describing the orbit in degrees.
    %Ecc    :Eccentric anomaly values along the Satellite trajectory in
             %radians.
    %E_time :Ellapsed time between Satellite launch and its pass over each S_lat/S_long location.
    
function [S_lat, S_long, Ecc,E_time] = satrackFoV(a, e, i, omega, w, theta, UTC,time,T)  

            %Constants:
            r2d  =180/pi;     %Radians to degrees conversion
            d2r = pi/180;      %degrees to radians conversion
            error=1e-11;      %Maximum error
            u =3998600.4415;  %Gravitational parameter  (fixe en km^2.s^2)
    
            Ei=acos((e+cos(theta*d2r))/(1+e*cos(theta*d2r)));   %Initial Eccentric anomaly
            Mi = Ei-e*sin(Ei);                                  %Initial mean anomaly

            p = zeros(1,length(time));
            q = zeros(1,length(time));
        
            px = zeros(1,length(time));
            qx = zeros(1,length(time));
        
            py = zeros(1,length(time));
            qy = zeros(1,length(time));
        
            pz = zeros(1,length(time));
            qz = zeros(1,length(time));
        
            Ecc= zeros(1,length(time));
            S_lat  = zeros(1,length(time));
            S_long = zeros(1,length(time));
            E_time = zeros(1,length(time));
            

     for j = 1:length(time)
        
         M  = Mi + (2*pi*time(j))/T;        %Mean anomaly at t
        
        %Kepler’s equation for the eccentric anomaly E
        
        if M < pi
            E=M+ e/2;
        else
            E=M- e/2;
        end
        
        ratio = (E - e*sin(E) - M)/(1 - e*cos(E));

        while abs(ratio) > error
              E=E- ratio;
              ratio = (E - e*sin(E) - M)/(1 - e*cos(E));          
        end
            
        Ecc(j)=E;
        
        %3D Satellite position
        
        p(j)=a*(cos(E)-e);
        q(j)=a*(sqrt(1-e^2))*sin(E);
        
        px(j) = cos(w*d2r)*cos(omega*d2r) - sin(w*d2r)*cos(i*d2r)*sin(omega*d2r);
        qx(j) = -sin(w*d2r)*cos(omega*d2r)- cos(w*d2r)*cos(i*d2r)*sin(omega*d2r);
         
        py(j) = cos(w*d2r)*sin(omega*d2r) + sin(w*d2r)*cos(i*d2r)*cos(omega*d2r);
        qy(j) = -sin(w*d2r)*sin(omega*d2r)+ cos(w*d2r)*cos(i*d2r)*cos(omega*d2r);
         
        pz(j) = sin(w*d2r)*sin(i*d2r);        
        qz(j) = sin(i*d2r)*cos(omega*d2r);
        
        r(j) = sqrt((p(j)*px(j)+q(j)*qx(j))^2+(p(j)*py(j) + q(j)*qy(j))^2+(p(j)*pz(j) + q(j)*qz(j))^2);
        
        %Local sub-satellite ground track in latitude/longitude
        
        S_lat(j) = (asin((p(j)*pz(j) + q(j)*qz(j))/ r(j)))*r2d;
         
        t_now=datestr(addtodate(datenum(UTC),time(j),'second'));%Current time since the Satellite launch 
        % datenum: A serial date number represents the whole and fractional number of days from a fixed, 
        %preset date (January 0, 0000) in the proleptic ISO calendar
        
        t    =floor(daysact('1-jan-2000 00:00:00', t_now));     %Time since 1 Jan 2000
        V  =datevec(t_now);      %To convert the current time in hours:elm(4), minutes:elm(5), seconds:elm(6) 
         %converts the datetime or duration value t to a date vector—that is, 
         % a numeric vector whose six elements represent the year, month, day, hour, minute, 
         % and second components of t.
        E_time(j)=time(j);
        
        alpha=mod(100.460618375 + 36000.770053608336*t + 0.0003879333*(t^2)+15*V(4)+V(5)/4+V(6)/240,360);
        
        S_long(j)= (atan2d((p(j)*py(j) + q(j)*qy(j)),(p(j)*px(j)+q(j)*qx(j))))-alpha;          
     end    
end


