function BDSPos=BDSSatPos(nav,ts)

%utility function that calculates the BeiDou satpos for each satellite and merge them into single table

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

BDSTimeWanted =[GPSweek,GPSsec-14];

BDSPos=[];

BDSNav=prepare_BDS(nav);

fieldnames_cell=fieldnames(BDSNav);

for i=1:length(fieldnames_cell)

    fieldname=fieldnames_cell{i};
    BDSPos_temp=getSatPosBDS(BDSTimeWanted,BDSNav.(fieldname),fieldname);
    BDSPos_temp.Time=ts;
    BDSPos=[BDSPos ; BDSPos_temp];
    
end

BDSPos=table2timetable(BDSPos);
BDSPos.Properties.VariableNames={'x','y','z','prn'};

end