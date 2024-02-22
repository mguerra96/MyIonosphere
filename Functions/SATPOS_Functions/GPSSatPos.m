function GPSPos=GPSSatPos(nav,ts)

%utility function that calculates the GPS satpos for each satellite and merge them into single table

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

GPSPos=[];

GPSNav=prepare_GPS(nav);

fieldnames_cell=fieldnames(GPSNav);

for i=1:length(fieldnames_cell)

    fieldname=fieldnames_cell{i};
    GPSPos_temp=getSatPosGPS([GPSweek,GPSsec],GPSNav.(fieldname),fieldname);
    GPSPos_temp.Time=ts;
    GPSPos=[GPSPos ; GPSPos_temp];
end

GPSPos=table2timetable(GPSPos);
GPSPos.Properties.VariableNames={'x','y','z','prn'};

end