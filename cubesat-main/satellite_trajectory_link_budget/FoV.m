%% Description
%This function estimates the radius of the Satellite coverage contour at a certain location with a specific elevation.

%% Input
%The input variables are the eccentric anomaly(ecc), the semimajor axis(a), the eccentricity(e),
%the argument of perigee(w) and the elevation angle in degrees(eps).

%% Output
%rov :the radius of the Field of View in degrees.

function [rov] = FoV(ecc,a, e, w, eps)

    %Constants
    R   =6378;         %Earth radius
    d2r = pi/180;      %degrees to radians conversion
    r2d = 180/pi;      %radians to degrees conversion
    
    %Elongation denoting the angle from the ascending node to the satellite
    ws=w+r2d*acos((cos(ecc)-e)/(1-e*cos(ecc)));
    
    %Coverage Angle
    AoV=pi/2-eps*d2r-asin( cos(eps*d2r)*((R*(1+e*cos(d2r*(ws-w))))/(a*(1-e^2)))  );
    %Field of View radius in degrees
    rov=km2deg(R*AoV);


end