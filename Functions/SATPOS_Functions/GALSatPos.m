function GALPos=GALSatPos(nav,ts)

%utility function that calculates the Galileo satpos for each satellite and merge them into single table

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

GALPos=[];

GALNav=prepare_GAL(nav);

fieldnames_cell=fieldnames(GALNav);

for i=1:length(fieldnames_cell)

    fieldname=fieldnames_cell{i};
    GALPos_temp=getSatPosGAL([GPSweek,GPSsec],GALNav.(fieldname),fieldname);
    GALPos_temp.Time=ts;
    GALPos=[GALPos ; GALPos_temp];

end

GALPos=table2timetable(GALPos);
GALPos.Properties.VariableNames={'x','y','z','prn'};

end