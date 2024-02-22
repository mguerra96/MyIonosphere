function [obs, obs_header]=my_rinexread2(obs_file_dir)

% Homemade function that reads rinex v2.xx files

finp = fopen(obs_file_dir,'r');
fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fclose(finp);

fileBuffer = fileBuffer{1};

% Exctract necessary data from header of obs file
MarkerName=fileBuffer{contains(fileBuffer,"MARKER NAME")}(1:4);
approxPosition=split(fileBuffer{contains(fileBuffer,"APPROX POSITION")});
obsTypes_Mat=char(fileBuffer(contains(fileBuffer,"TYPES OF OBSERV")));
FileVersion=split(fileBuffer{contains(fileBuffer,"RINEX VERSION")});
TimeOfFirstObs=split(fileBuffer{contains(fileBuffer,"TIME OF FIRST OBS")});
FirstObsTime=datetime(my_str2num(TimeOfFirstObs{2}),my_str2num(TimeOfFirstObs{3}),my_str2num(TimeOfFirstObs{4}),my_str2num(TimeOfFirstObs{5}),my_str2num(TimeOfFirstObs{6}),my_str2num(TimeOfFirstObs{7}));

obs_header.ApproxPosition=[my_str2num(approxPosition{2}) my_str2num(approxPosition{3}) my_str2num(approxPosition{4})];
obs_header.FileVersion=my_str2num(FileVersion{2});
obs_header.FirstObsTime=FirstObsTime;
obs_header.MarkerName=MarkerName;

headerSize=find(contains(fileBuffer,"END OF HEADER")); %find length of header in rinex file

% indentify number and name of observables present in rinex file
numOfObs=str2double(obsTypes_Mat(1,5:6));
obsTypes_Mat=obsTypes_Mat(:,11:60);
obsTypes_Mat=strsplit(reshape([obsTypes_Mat repmat(blanks(3),size(obsTypes_Mat,1),1)]',1,[]));
obsTypes=obsTypes_Mat(1:numOfObs);


bodyBuffer = fileBuffer(headerSize+1:end);
BodyBuffer_Mat = char(bodyBuffer);

splice_lines_previous=find(contains(string(BodyBuffer_Mat(:,:)),'RINEX FILE SPLICE'))-1; %when RINEX FILE SPLICE is performed a new line is added before the first COMMENT line, which sploils the parsing algorithm
BodyBuffer_Mat(splice_lines_previous,:)=[]; %Delete the line before RINEX FILE SPLICE
bodyBuffer(splice_lines_previous,:)=[]; %Delete the line before RINEX FILE SPLICE

post_header_comments_lines=find(contains(string(BodyBuffer_Mat(:,:)),'other post-header comments skipped'))-1; %Sometis the splicing process COMMENT are merged into a single line containing "other post-header comments skipped"
lines_to_del=BodyBuffer_Mat(post_header_comments_lines,:); %Check that those lines are not observables
lines_to_del(lines_to_del==' ')=[];

if length(lines_to_del)==length(post_header_comments_lines)*2 %Check that those are not observables (slicing line has only two char that are not blank)
    BodyBuffer_Mat(post_header_comments_lines,:)=[]; %Delete the line before RINEX FILE SPLICE
    bodyBuffer(post_header_comments_lines,:)=[]; %Delete the line before RINEX FILE SPLICE
end

comment_lines=contains(string(BodyBuffer_Mat(:,:)),'COMMENT');
useless_time_lines=string(BodyBuffer_Mat(:,2:3))==string(obs_file_dir(end-2:end-1)) & string(BodyBuffer_Mat(:,29))~="0";

BodyBuffer_Mat=BodyBuffer_Mat(~comment_lines & ~useless_time_lines,:);

time_lines=string(BodyBuffer_Mat(:,2:3))==string(obs_file_dir(end-2:end-1));

key_lines=contains(string(BodyBuffer_Mat(:,:)),'G') | contains(string(BodyBuffer_Mat(:,:)),'R') | contains(string(BodyBuffer_Mat(:,:)),'E') | contains(string(BodyBuffer_Mat(:,:)),'C') | contains(string(BodyBuffer_Mat(:,:)),'S');

times=datetime(my_str2num(TimeOfFirstObs{2}),my_str2num(BodyBuffer_Mat(time_lines,5:6)),my_str2num(BodyBuffer_Mat(time_lines,8:9)),my_str2num(BodyBuffer_Mat(time_lines,11:12)),my_str2num(BodyBuffer_Mat(time_lines,14:15)),my_str2num(BodyBuffer_Mat(time_lines,17:18)));
numOfSats=my_str2num(BodyBuffer_Mat(time_lines,31:32));

SatelliteIDs=reshape(BodyBuffer_Mat(key_lines,33:68)',1,[]);
SatelliteIDs=string(reshape(SatelliteIDs,3,[])');
SatelliteIDs=SatelliteIDs(SatelliteIDs~="   ");

temp_tab=table(repelem(times,numOfSats));
temp_tab.SatelliteID(:)=nan;
temp_tab.SatelliteID=SatelliteIDs;
temp_tab.Properties.VariableNames={'Time','SatelliteID'};

observablesBuffer_mat=BodyBuffer_Mat(~key_lines,:);

if size(observablesBuffer_mat,2)<80
    observablesBuffer_mat=[observablesBuffer_mat repmat(blanks(80-size(observablesBuffer_mat,2)),size(observablesBuffer_mat,1),1)];
end

obsBuffer=cell(1,ceil(numOfObs/5));

for lineNum=1:ceil(numOfObs/5)
    obsBuffer{lineNum}=observablesBuffer_mat(lineNum:ceil(numOfObs/5):end,:);
end

for obsNum=1:numOfObs
    lineNum=ceil(obsNum/5);
    charPos = ((obsNum -(lineNum - 1)*5)-1)*16 + 1;
    obs=obsBuffer{lineNum}(:,charPos:charPos+13);
    temp_tab.(obsTypes{obsNum})=double(string(obs));
end

temp_tab.prn(:)=nan;

temp_tab.prn=char(temp_tab.SatelliteID);
temp_tab.SatelliteID=temp_tab.prn(:,2:3);

obs=struct();

obs.GPS=table2timetable(temp_tab(contains(string(temp_tab.prn),"G"),:));
obs.GLONASS=table2timetable(temp_tab(contains(string(temp_tab.prn),"R"),:));
obs.BeiDou=table2timetable(temp_tab(contains(string(temp_tab.prn),"C"),:));
obs.Galileo=table2timetable(temp_tab(contains(string(temp_tab.prn),"E"),:));
obs.SBAS=table2timetable(temp_tab(contains(string(temp_tab.prn),"S"),:));

end
