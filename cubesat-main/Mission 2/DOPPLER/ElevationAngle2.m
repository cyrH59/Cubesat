function E = ElevationAngle2(S_long,S_lat,Site_Long,Site_Lat,H)
N=length(S_long);
E=zeros(1,N);
earth = referenceSphere('Earth');
R=6371*1000;
for i=1:N
[~,E(i),~] = geodetic2aer(S_lat(i),S_long(i),H*1e3+R,Site_Lat,Site_Long,R,earth);
end
end
