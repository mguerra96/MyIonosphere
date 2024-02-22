function [lat,lon,azi,ele]=Calculate_IPP(rec_pos,sat_pos1,sat_pos2,sat_pos3,HIPP)

% Function that calculates the IPP location given the receiver ECEF position, the list of ECEF coordinates of the satellite and the ionospheric shell height

Re = 6371000;
r = HIPP*1000 + Re ;
xA = rec_pos(1);
yA = rec_pos(2);
zA = rec_pos(3);
xB = sat_pos1;
yB = sat_pos2;
zB = sat_pos3;

xc = 0;
yc = 0;
zc = 0;

x1 = xA + (xB - xA) * 0 ;
x2 = xA + (xB - xA) * 1 ;
y1 = yA + (yB - yA) * 0 ;
y2 = yA + (yB - yA) * 1 ;
z1 = zA + (zB - zA) * 0 ;
z2 = zA + (zB - zA) * 1 ;

a = (x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2 ;
b = 2 * ((x2 - x1) * (x1 - xc) + (y2 - y1) * (y1 - yc) + (z2 - z1) * (z1 - zc)) ;
c = xc ^ 2 + yc ^ 2 + zc ^ 2 + x1 ^ 2 + y1 ^ 2 + z1 ^ 2 - 2 * (xc * x1 + yc * y1 + zc * z1) - r ^ 2 ;


t1 = (-b + sqrt(b ^ 2 - 4 * a * c)) / (2 * a);
t2 = (-b - sqrt(b ^ 2 - 4 * a * c)) / (2 * a);

if isreal(t1) && isreal(t2)
    x_ipp = x1 + (x2 -  x1) * t1;
    y_ipp = y1 + (y2 - y1) * t1;
    z_ipp = z1 + (z2 - z1) * t1;
else
    x_ipp = 0;
    y_ipp = 0;
    z_ipp = 0;
end

lla=ecef2lla([x_ipp , y_ipp , z_ipp]);  %convert IPP ECEF coordinates to LLA ones

lat=lla(1);
lon=lla(2);

[azi,ele,~]=lookangles(ecef2lla(rec_pos),[sat_pos1 sat_pos2 sat_pos3]); %obtain azimuth and elevation of satellite given SATPOS and receiver location

end