function QZSSPos=QZSSSatPos(nav,ts)

%utility function that calculates the Galileo satpos for each satellite and merge them into single table

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

QZSSPos=[];

QZSSNav=prepare_QZSS(nav);

fieldnames_cell=fieldnames(QZSSNav);

for i=1:length(fieldnames_cell)

    fieldname=fieldnames_cell{i};
    QZSSPos_temp=getSatPosQZSS([GPSweek,GPSsec],QZSSNav.(fieldname),fieldname);
    QZSSPos_temp.Time=ts;
    QZSSPos=[QZSSPos ; QZSSPos_temp];

end

QZSSPos=table2timetable(QZSSPos);
QZSSPos.Properties.VariableNames={'x','y','z','prn'};

end