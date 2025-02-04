function GLOPos=GLOSatPos(nav,ts,t_res)

% utility function that calculates the GLONASS satpos for each satellite and merge them into single table
% leap seconds are not considered, there is an error in GLONASS position, which is negligible for ionospheric studies

[GPSweek,GPSsec] = greg2gps([year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts)]);

GLOTimeWanted = [GPSweek,GPSsec];

GLOPos=[];

GLONav=prepare_GLO(nav);

if isfield(GLONav,"R00")
    GLONav=rmfield(GLONav,"R00");
end

fieldnames_cell=fieldnames(GLONav);

for i=1:length(fieldnames_cell)
    fieldname=fieldnames_cell{i};
    GLOPos_temp=zeros(length(ts),3);
    GLOPos_temp=array2table(GLOPos_temp);
    GLOPos_temp.prn(:)="placeholer";
    GLOPos_temp.Time(:)=datetime(2020,1,1,1,1,1);
    if size(GLONav.(fieldname),2)<2
        continue
    end
    for j=1:size(GLONav.(fieldname),2)
        if j==1
            mask= GLOTimeWanted(:,2)<GLONav.(fieldname)(14,j+1);
        elseif j==size(GLONav.(fieldname),2)
            mask= GLOTimeWanted(:,2)>=GLONav.(fieldname)(14,j);
        else
            mask= GLOTimeWanted(:,2)>=GLONav.(fieldname)(14,j) & GLOTimeWanted(:,2)<GLONav.(fieldname)(14,j+1);
        end
        GLOPos_temp(mask,:).Time=ts(mask);
        GLOPos_temp(mask,1:4)=getSatPosGLO(GLOTimeWanted(mask,:),GLONav.(fieldname)(:,j),fieldname,t_res);

    end

    GLOPos=[GLOPos ; GLOPos_temp];

end

GLOPos=table2timetable(GLOPos);
GLOPos.Properties.VariableNames={'x','y','z','prn'};

end