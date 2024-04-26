function [obs, obs_header]=my_rinexread3(obs_file_dir)

% Homemade function that reads rinex v3.xx files

finp = fopen(obs_file_dir,'r');
fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fclose(finp);

fileBuffer = fileBuffer{1};

if fileBuffer{1}(1)=='"' && fileBuffer{1}(end)=='"'
    fileBuffer=cellfun(@myCleaner,fileBuffer,'UniformOutput',false);
end

headerSize=find(contains(fileBuffer,"END OF HEADER")); %find length of header in rinex file

HeaderBuffer=fileBuffer(1:headerSize);

% Exctract necessary data from header of obs file
MarkerName=HeaderBuffer{contains(HeaderBuffer,"MARKER NAME") & ~contains(HeaderBuffer,"COMMENT")}(1:4);
approxPosition=split(HeaderBuffer{contains(HeaderBuffer,"APPROX POSITION") & ~contains(HeaderBuffer,"COMMENT")});

FileVersion=split(HeaderBuffer{contains(HeaderBuffer,"RINEX VERSION")});
TimeOfFirstObs=split(HeaderBuffer{contains(HeaderBuffer,"TIME OF FIRST OBS")});
FirstObsTime=datetime(my_str2num(TimeOfFirstObs{2}),my_str2num(TimeOfFirstObs{3}),my_str2num(TimeOfFirstObs{4}),my_str2num(TimeOfFirstObs{5}),my_str2num(TimeOfFirstObs{6}),my_str2num(TimeOfFirstObs{7}));

obs_header.ApproxPosition=[my_str2num(approxPosition{2}) my_str2num(approxPosition{3}) my_str2num(approxPosition{4})];
obs_header.FileVersion=my_str2num(FileVersion{2});
obs_header.FirstObsTime=FirstObsTime;
obs_header.MarkerName=MarkerName;

obsTypes_Mat=char(HeaderBuffer(contains(HeaderBuffer,"OBS TYPES")));
Sys_Obs_Types=[obsTypes_Mat(obsTypes_Mat(:,1)~=' ',1) obsTypes_Mat(obsTypes_Mat(:,1)~=' ',5:6)];
obsNames_Mat=obsTypes_Mat(:,8:59);

for iSys=1:size(Sys_Obs_Types,1)
    numOfLines=ceil(double(string(Sys_Obs_Types(iSys,2:3)))/13);
    rowIdx=find(obsTypes_Mat(:,1)==Sys_Obs_Types(iSys));
    Obs_Types.(Sys_Obs_Types(iSys,1))=split(string(reshape(obsNames_Mat(rowIdx:rowIdx+numOfLines-1,:)',1,[])));
    if Obs_Types.(Sys_Obs_Types(iSys,1))(end)==""
        Obs_Types.(Sys_Obs_Types(iSys,1))(end)=[];
    end
end

bodyBuffer = fileBuffer(headerSize+1:end);
BodyBuffer_Mat = char(bodyBuffer);

BodyBuffer_Mat=BodyBuffer_Mat(sum((BodyBuffer_Mat(:,1:3)==' '),2)<2,:);

TimeLines_Keys=BodyBuffer_Mat(:,1)=='>';
obsTimeLines=BodyBuffer_Mat(TimeLines_Keys,:);

Times=datetime(obsTimeLines(:,3:25),'InputFormat','yyyy MM dd HH mm ss.SSS');
NumOfObsAtTimes=double(string(obsTimeLines(:,34:35)));

SatelliteIDs=BodyBuffer_Mat(~TimeLines_Keys,1:3);
SatelliteIDs(SatelliteIDs==' ')='0';

temp_tab=timetable(repelem(Times,NumOfObsAtTimes));   %Create a table with each timestamp reapeat a number of times equal to the num of sats for given time
temp_tab.SatelliteID(:)=nan;
temp_tab.SatelliteID=SatelliteIDs;
temp_tab.Properties.VariableNames={'SatelliteID'};

obsBuffer_Mat=BodyBuffer_Mat(~TimeLines_Keys,1:end);

obs.GPS=temp_tab(temp_tab.SatelliteID(:,1)=='G',:);
obs.Galileo=temp_tab(temp_tab.SatelliteID(:,1)=='E',:);
obs.BeiDou=temp_tab(temp_tab.SatelliteID(:,1)=='C',:);
obs.GLONASS=temp_tab(temp_tab.SatelliteID(:,1)=='R',:);
obs.SBAS=temp_tab(temp_tab.SatelliteID(:,1)=='S',:);
obs.NavIC=temp_tab(temp_tab.SatelliteID(:,1)=='I',:);
obs.QZSS=temp_tab(temp_tab.SatelliteID(:,1)=='J',:);

if max(str2num(Sys_Obs_Types(:,2:3)))*16+1>size(obsBuffer_Mat,2)
    obsBuffer_Mat=[obsBuffer_Mat repmat(' ',[size(obsBuffer_Mat,1) max(str2num(Sys_Obs_Types(:,2:3)))*16+1-size(obsBuffer_Mat,2)])];
end

%%
for iSys=fieldnames(Obs_Types)'

    switch string(iSys)
        case "G"
            fieldname="GPS";
        case "E"
            fieldname="Galileo";
        case "R"
            fieldname="GLONASS";
        case "C"
            fieldname="BeiDou";
        case "S"
            fieldname="SBAS";
        case "I"
            fieldname="NavIC";
        case "J"
            fieldname="QZSS";
    end

    for iObservable=Obs_Types.(string(iSys))'
        obsNum=find(iObservable==Obs_Types.(string(iSys))');
        obs.(fieldname).(iObservable)=double(string(obsBuffer_Mat(obsBuffer_Mat(:,1)==char(iSys),4+(obsNum-1)*16+1:4+obsNum*16-3)));
    end
    obs.(fieldname).SatelliteID=double(string(obs.(fieldname).SatelliteID(:,2:3)));
end
%%
    function x=myCleaner(x) %function that removes " at the beginning and end of rinex obs lines
        x(1)=[];
        x(end)=[];
    end

end