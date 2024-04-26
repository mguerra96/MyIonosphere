function MoDip=Calculate_MoDip(lat,lon,time,HIPP)

[~,~,~,Inclination] = igrfmagm(HIPP*10^3,lat,lon,decyear(time));
MoDip=atand(deg2rad(Inclination)/(sqrt(cosd(lat))));

end
