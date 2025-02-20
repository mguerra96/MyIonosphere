function QZSSNav=prepare_QZSS(nav)

%prepare Galileo ephemeris for the SatellitePosition function

QZSSNav=struct();

for sat=unique(nav.QZSS.SatelliteID)'

    ephe=nav.QZSS(nav.QZSS.SatelliteID==sat,:);

    if isempty(ephe)
        continue
    end

    ephe=ephe(round(height(ephe)/2),:);

    [GPSweek,GPSsec] = greg2gps([year(ephe.Time) month(ephe.Time) day(ephe.Time) hour(ephe.Time) minute(ephe.Time) second(ephe.Time)]);

    ephe_tab(1,1)=year(ephe.Time);
    ephe_tab(2,1)=month(ephe.Time);
    ephe_tab(3,1)=day(ephe.Time);
    ephe_tab(4,1)=hour(ephe.Time);
    ephe_tab(5,1)=minute(ephe.Time);
    ephe_tab(6,1)=second(ephe.Time);
    ephe_tab(7,1)=GPSweek;
    ephe_tab(8,1)=GPSsec;
    ephe_tab(9,1)=weekday(ephe.Time);
    ephe_tab(10,1)=floor(date2doy(datenum(ephe.Time)));
    ephe_tab(11,1)=datenum(ephe.Time);
    ephe_tab(12,1)=ephe.SVClockBias;
    ephe_tab(13,1)=ephe.SVClockDrift;
    ephe_tab(14,1)=ephe.SVClockDriftRate;
    ephe_tab(15,1)=ephe.IODE;
    ephe_tab(16,1)=ephe.Crs;
    ephe_tab(17,1)=ephe.Delta_n;
    ephe_tab(18,1)=ephe.M0;
    ephe_tab(19,1)=ephe.Cuc;
    ephe_tab(20,1)=ephe.Eccentricity;
    ephe_tab(21,1)=ephe.Cus;
    ephe_tab(22,1)=ephe.sqrtA^2;
    ephe_tab(23,1)=ephe.Toe;
    ephe_tab(24,1)=ephe.Cic;
    ephe_tab(25,1)=ephe.OMEGA0;
    ephe_tab(26,1)=ephe.Cis;
    ephe_tab(27,1)=ephe.i0;
    ephe_tab(28,1)=ephe.Crc;
    ephe_tab(29,1)=ephe.omega;
    ephe_tab(30,1)=ephe.OMEGA_DOT;
    ephe_tab(31,1)=ephe.IDOT;


    fieldname=['J' num2str(sat,'%02d')];
    QZSSNav.(fieldname)=ephe_tab;

end

end