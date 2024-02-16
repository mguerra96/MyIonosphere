function [obs, obs_header]=my_rinexread2(obs_file_dir)

finp = fopen(obs_file_dir,'r');
fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fclose(finp);

fileBuffer = fileBuffer{1};

obsType={};

for i=1:size(fileBuffer,1)
    if contains(fileBuffer{i},"MARKER NAME")
        MarkerName=fileBuffer{i}(1:4);
    end
    if contains(fileBuffer{i},"APPROX POSITION")
        approxPosition=fileBuffer{i};
    end
    if contains(fileBuffer{i},"TYPES OF OBSERV")
        obsTypet=split(fileBuffer{i});
        obsType=[obsType ; obsTypet];
    end
    if contains(fileBuffer{i},"RINEX VERSION")
        FileVersion=split(fileBuffer{i});
    end
    if contains(fileBuffer{i},"TIME OF FIRST OBS")
        TimeOfFirstObs=split(fileBuffer{i});
        FirstObsTime=datetime(str2num(TimeOfFirstObs{2}),str2num(TimeOfFirstObs{3}),str2num(TimeOfFirstObs{4}),str2num(TimeOfFirstObs{5}),str2num(TimeOfFirstObs{6}),str2num(TimeOfFirstObs{7}));
    end
    if contains(fileBuffer{i},"END OF HEADER")
        headerSize=i;
        break
    end
end

approxPosition=split(approxPosition);
approxPosition=[str2num(approxPosition{2}) str2num(approxPosition{3}) str2num(approxPosition{4})];

obs_header.ApproxPosition=approxPosition;
obs_header.FileVersion=str2num(FileVersion{2});
obs_header.FirstObsTime=FirstObsTime;
obs_header.MarkerName=MarkerName;

headBuffer = fileBuffer(1:headerSize);
bodyBuffer = fileBuffer(headerSize+1:end);

numOfObs=str2num(obsType{2});
numOfLineObs=ceil(numOfObs/9);

switch numOfLineObs
    case 1
        nameOfObs=obsType(3:2+numOfObs);
    case 2
        FirstLine=obsType(3:11);
        FirstLine{9}=FirstLine{9}(1:2);
        SecondLine=obsType(17:16+mod(numOfObs,9));
        nameOfObs=[FirstLine ; SecondLine];
    case 3
        FirstLine=obsType(3:11);
        FirstLine{9}=FirstLine{9}(1:2);
        SecondLine=obsType(17:25);
        SecondLine{9}=SecondLine{9}(1:2);
        ThirdLine=obsType(31:30+mod(numOfObs,9));
        nameOfObs=[FirstLine ; SecondLine ; ThirdLine];
    otherwise
        fprintf('More than 3 lines of ObsType, possible error\n')
end



tmp = char(bodyBuffer);

comment_lines=contains(string(tmp(:,:)),'COMMENT');
useless_time_lines=string(tmp(:,2:3))==string(obs_file_dir(end-2:end-1)) & string(tmp(:,29))~="0";

tmp=tmp(~comment_lines & ~useless_time_lines,:);

time_lines=string(tmp(:,2:3))==string(obs_file_dir(end-2:end-1));

key_lines=contains(string(tmp(:,:)),'G') | contains(string(tmp(:,:)),'R') | contains(string(tmp(:,:)),'E') | contains(string(tmp(:,:)),'C') | contains(string(tmp(:,:)),'S');

times=datetime(str2num(TimeOfFirstObs{2}),str2num(tmp(time_lines,5:6)),str2num(tmp(time_lines,8:9)),str2num(tmp(time_lines,11:12)),str2num(tmp(time_lines,14:15)),str2num(tmp(time_lines,17:18)));
numOfSats=str2num(tmp(time_lines,31:32));

SatelliteIDs=reshape(tmp(key_lines,33:68)',1,[]);
SatelliteIDs(SatelliteIDs==' ')=[];
SatelliteIDs=reshape(SatelliteIDs,3,[])';

temp_tab=table(repelem(times,numOfSats));
temp_tab.SatelliteID(:)=nan;
temp_tab.SatelliteID=SatelliteIDs;
temp_tab.Properties.VariableNames={'Time','SatelliteID'};

bodybuff=bodyBuffer(~key_lines);

for lineNum=1:ceil(numOfObs/5)
    obsBuffer{lineNum}=char(bodybuff(lineNum:ceil(numOfObs/5):end,:));
end

first_lines=char(bodybuff(1:2:end,:));
seconds_lines=char(bodybuff(2:2:end,:));

for obsNum=1:numOfObs
    lineNum=ceil(obsNum/5);
    charPos = ((obsNum -(lineNum - 1)*5)-1)*16 + 1;
    obs=obsBuffer{lineNum}(:,charPos:charPos+13);
    temp_tab.(nameOfObs{obsNum})=str2double(cellstr(obs));
end

temp_tab.prn(:)=nan;

temp_tab.prn=temp_tab.SatelliteID;
temp_tab.SatelliteID=temp_tab.prn(:,2:3);

obs=struct();

obs.GPS=table2timetable(temp_tab(contains(string(temp_tab.prn),"G"),:));
obs.GLONASS=table2timetable(temp_tab(contains(string(temp_tab.prn),"R"),:));
obs.BeiDou=table2timetable(temp_tab(contains(string(temp_tab.prn),"C"),:));
obs.Galileo=table2timetable(temp_tab(contains(string(temp_tab.prn),"E"),:));
obs.SBAS=table2timetable(temp_tab(contains(string(temp_tab.prn),"S"),:));

end
