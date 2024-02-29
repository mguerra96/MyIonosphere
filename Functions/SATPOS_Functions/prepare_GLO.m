function GLONav=prepare_GLO(nav)

%prepare GLONASS ephemeris for the SatellitePosition function

GLONav=struct();

for sat=unique(nav.GLONASS.SatelliteID)

ephes=nav.GLONASS(nav.GLONASS.SatelliteID==sat,:);

if isempty(ephes)
    continue
end

for j=1:size(ephes,1)
ephe=ephes(j,:);

[GPSweek,GPSsec] = greg2gps([year(ephe.Time) month(ephe.Time) day(ephe.Time) hour(ephe.Time) minute(ephe.Time) second(ephe.Time)]);

ephe_tab(1,j)=year(ephe.Time);
ephe_tab(2,j)=month(ephe.Time);
ephe_tab(3,j)=day(ephe.Time);
ephe_tab(4,j)=hour(ephe.Time);
ephe_tab(5,j)=minute(ephe.Time);
ephe_tab(6,j)=second(ephe.Time);
ephe_tab(7,j)=GPSweek;
ephe_tab(8,j)=GPSsec;
ephe_tab(9,j)=weekday(ephe.Time);
ephe_tab(10,j)=floor(date2doy(datenum(ephe.Time)));
ephe_tab(11,j)=datenum(ephe.Time);
ephe_tab(12,j)=ephe.SVClockBias;
ephe_tab(13,j)=ephe.SVFrequencyBias;
ephe_tab(14,j)=ephe.MessageFrameTime;
ephe_tab(15,j)=ephe.PositionX;
ephe_tab(16,j)=ephe.VelocityX;
ephe_tab(17,j)=ephe.AccelerationX;
ephe_tab(18,j)=ephe.Health;
ephe_tab(19,j)=ephe.PositionY;
ephe_tab(20,j)=ephe.VelocityY;
ephe_tab(21,j)=ephe.AccelerationY;
ephe_tab(22,j)=ephe.FrequencyNumber;
ephe_tab(23,j)=ephe.PositionZ;
ephe_tab(24,j)=ephe.VelocityZ;
ephe_tab(25,j)=ephe.AccelerationZ;   
ephe_tab(26,j)=ephe.AgeOperationInfo;
ephe_tab(27,j)=nan;
ephe_tab(28,j)=nan;
ephe_tab(29,j)=nan;
ephe_tab(30,j)=nan;
ephe_tab(31,j)=nan;
ephe_tab(32,j)=nan;
ephe_tab(33,j)=nan;
ephe_tab(34,j)=nan;
ephe_tab(35,j)=nan;
ephe_tab(36,j)=nan;
ephe_tab(37,j)=nan;
ephe_tab(38,j)=nan;
ephe_tab(39,j)=nan;
ephe_tab(40,j)=nan;
ephe_tab(41,j)=nan;
ephe_tab(42,j)=nan;

fieldname=['R' num2str(sat,'%02d')];
GLONav.(fieldname)=ephe_tab;

end

end