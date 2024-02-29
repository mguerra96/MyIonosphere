function NavICPos=NavICSatPos(nav,ts)

%utility function that calculates the NavIC satpos for each satellite and merge them into single table

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

NavICPos=[];

NavICNav=prepare_NavIC(nav);

fieldnames_cell=fieldnames(NavICNav);

for i=1:length(fieldnames_cell)

    fieldname=fieldnames_cell{i};
    NavICPos_temp=getSatPosNavIC([GPSweek,GPSsec],NavICNav.(fieldname),fieldname);
    NavICPos_temp.Time=ts;
    NavICPos=[NavICPos ; NavICPos_temp];

end

NavICPos=table2timetable(NavICPos);
NavICPos.Properties.VariableNames={'x','y','z','prn'};

end