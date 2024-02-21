function [CleanOutputs , Statistics]=MyIonosphere(MyIonoSettings)

% FUNCTION THAT READS RINEX OBSERVATIONAL FILES (v2.xx and v3.xx) AND CALCULATES GGFLC AND IPPS
% THIS FUNCTION CAN HANDLE GPS, GLONASS, GALILEO AND BEIDOU SATELLITES
%
% INPTUS ARE:
% ts,te ---> start_time and end_time in datetime format
% t_res ---> time resolution of rinex observational files
% HIPP ---> Height of the ionospheric layer for the calculation of the iono piercing point
% Elevation_Cutoff ---> Minimum acceptable elevation, every data point with elevation lower than cutoff is not included
% GNSS_Systems ---> List of GNSS constellations to consider
%
% Written by Marco Guerra

warning off

% SETTINGS MANAGER

ts=MyIonoSettings.StartTime;
te=MyIonoSettings.StopTime;

[t_res,HIPP,Elevation_Cutoff,GNSS_Systems,ToCalibrate,ToVertical,MinArcLength]=SettingsManager(MyIonoSettings);

if isfield(MyIonoSettings,'RinexDir')
    DB_Dir=MyIonoSettings.RinexDir;
else
    fprintf('ERROR: No RINEX_FILES directory in input settings')
    return
end

StartTicTime=tic;
StepTicTime=tic;
Statistics=struct();
Statistics.TimeNeeded=struct();


dt=ts:seconds(t_res):te;
doys=unique(floor(date2doy(datenum(dt))));
yy=year(ts);


% DOWLOADING NEEDED BRDC FILES AND CALCULATING SATELLITE POSITIONS

for doy=doys
    BRDC_Grabber(doy,yy,DB_Dir);
end

fprintf('CALCULATING SATELLITE POSITION...\n')
[SATPOS , FrequencyNumber]=SatellitesPosition(t_res,dt,DB_Dir,GNSS_Systems);
Statistics.TimeNeeded.SATPOS=toc(StepTicTime);
StepTicTime=tic;


% EXTRACTING OBS FILES IF THEY ARE HATANAKA COMPRESSED OR GZIPPED

if t_res==30
    Unzip_And_DeHata(DB_Dir)
end

% READING RINEX OBS FILES AND MERGING OBSERVATIONS WITH SATELLITE POSITIONS

obs_files=[dir([DB_Dir '\obs\*.rnx']) ; dir([DB_Dir '\obs\*.*o'])];

if isempty(obs_files)
    fprintf('ERROR: No observational files for given time period\n')
    return
end

Outputs=cell(size(obs_files));
Outputs_key=zeros(size(obs_files));

if ~exist([DB_Dir '\Errors\' datestr(ts,'dd_mm_yy')],'dir')
    mkdir([DB_Dir '\Errors\' datestr(ts,'dd_mm_yy')])
end

fprintf('READING RINEX FILES...\n')

WaitMessage = parfor_wait(length(obs_files), 'Waitbar', true);

for fileIdx=1:size(obs_files,1)

    fprintf('%d of %d\n',[fileIdx , size(obs_files,1)])
    obs_file=obs_files(fileIdx);

    try
        [obs, obs_header]=MyRinexRead(obs_file);
    catch ME
        obs=[];
        obs_header=[];
        fprintf(['Error loading obs file: ' obs_file.name '\n']);
        Outputs{fileIdx}={ME obs_file.name};
        Outputs_key(fileIdx,1)=-1;
        if ~exist([DB_Dir '\Errors'],'dir')
            mkdir([DB_Dir '\Errors'])
        end
        movefile([obs_file.folder '\' obs_file.name],[DB_Dir  '\Errors\' datestr(ts,'dd_mm_yy') '\' obs_file.name],'f');
    end


    if ~isempty(obs) && year(obs_header.FirstObsTime)==yy && sum(floor(date2doy(datenum(obs_header.FirstObsTime)))==doys)>0
        try
            Outputs{fileIdx}=MergeObsSatPos(SATPOS,Compute_GFLC(obs,obs_header,FrequencyNumber.(datestr(obs_header.FirstObsTime,'mmmddyyyy')),GNSS_Systems),obs_header,HIPP);
            Outputs{fileIdx}.stat(:)=string(obs_header.MarkerName(1:4));
            Outputs_key(fileIdx,1)=1;
        catch ME
            fprintf(['Error computing GFLC for file: ' obs_file.name '\n']);
            Outputs{fileIdx}={ME obs_file.name};
            Outputs_key(fileIdx,1)=-1;
            if ~exist([DB_Dir '\Errors'],'dir')
                mkdir([DB_Dir '\Errors'])
            end
            movefile([obs_file.folder '\' obs_file.name],[DB_Dir '\Errors\'  datestr(ts,'dd_mm_yy') '\' obs_file.name],'f');
        end

    end

    WaitMessage.Send;

end

WaitMessage.Destroy;

Statistics.TimeNeeded.ObsRead_GFLCSATPOS=toc(StepTicTime);
StepTicTime=tic;

Statistics.Errors=Outputs(Outputs_key==-1);
Statistics.NumOfSuccesses=sum(Outputs_key==1);
Statistics.NumOfErrors=sum(Outputs_key==-1);

CleanOutputs=Outputs(Outputs_key==1);

if isempty(CleanOutputs)
    fprintf('ERROR: No valid observational files provided\n')
    return
end

% CREATION OF THE DATAFRAME WITH ALL THE OBSERVATIONAL ARCS
fprintf('CREATING DATAFRAME WITH OBSERVATIONAL ARCS...\n')
CleanOutputs=vertcat(CleanOutputs{:});
CleanOutputs.ArcID=strcat(CleanOutputs.stat,"_",CleanOutputs.prn);
CleanOutputs=CleanOutputs(CleanOutputs.ele>=Elevation_Cutoff,:);


% CREATION OF ID OF SINGLE ARCS TO ALLOW OPEARTION ON ARCS
fprintf('CREATING ARC UNIQUE IDENTIFIER...\n')
CleanOutputs=sortrows(timetable2table(CleanOutputs),{'ArcID','Time'});
Arc_Splitter_Func=@(x) Arc_Splitter(x,t_res);
ArcIDNum=sortrows(rowfun(Arc_Splitter_Func,CleanOutputs,"GroupingVariables","ArcID","InputVariables","Time","OutputVariableNames","ArcIDNum"),'ArcID');
CleanOutputs.ArcID=strcat(CleanOutputs.ArcID,"_",ArcIDNum.ArcIDNum);
CleanOutputs=removevars(CleanOutputs,{'stat','prn'});
CleanOutputs.Properties.VariableNames={'Time','GFLC','Lat','Lon','Azi','Ele','ArcID'};
Statistics.TimeNeeded.PostProcessingB4NeQuick=toc(StepTicTime);
StepTicTime=tic;
CleanOutputs=sortrows(CleanOutputs,{'ArcID','Time'});


% DROP ARCS THAT ARE TOO SHORT
IDCounts=groupcounts(CleanOutputs,'ArcID');
Arc2Delete=IDCounts(IDCounts.GroupCount<MinArcLength,:);
CleanOutputs=CleanOutputs(~contains(CleanOutputs.ArcID,Arc2Delete.ArcID),:);


% CORRECTION OF PHASE JUMPS TO AVOID DETRENDING OUTLIERS
fprintf('CORRECTION OF PHASE JUMPS...\n')
PhaseJumpsCorrector_f=@(x,t) PhaseJumpsCorrector(x,t,5);
GFLC_Corrected=rowfun(PhaseJumpsCorrector_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Time'},"OutputVariableNames",{'GFLC','Time'});
GFLC_Corrected=sortrows(GFLC_Corrected,{'ArcID','Time'});
CleanOutputs.GFLC=GFLC_Corrected.GFLC;
Calibrated=false;
% CALIBRATION WITH NeQuick2 TO REDUCE DETRENING ERRORS ON AMPLITUDE

if ToCalibrate
    fprintf('CALIBRATION WITH NeQuick2...\n')
    NeQuick_Calibrator_Func=@(stec,latitude,longitude,azimuth,elevation,time) NeQuick_Calibrator(stec,latitude,longitude,azimuth,elevation,time);
    sTEC=rowfun(NeQuick_Calibrator_Func,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Lat','Lon','Azi','Ele','Time'},"OutputVariableNames","sTEC");
    CleanOutputs.sTEC=sTEC.sTEC;
    CleanOutputs=CleanOutputs(~isnan(CleanOutputs.sTEC),:);
    Statistics.TimeNeeded.NeQuickCalibration=toc(StepTicTime);
    Calibrated=true;
end

if ToVertical
    vert_f=@(vtec,ele) Verticalization(vtec,ele,HIPP);
   if Calibrated
        vTEC=rowfun(vert_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'sTEC','Ele'},"OutputVariableNames","vTEC");
        CleanOutputs.vTEC=vTEC.vTEC;
   else    
        vTEC=rowfun(vert_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Ele'},"OutputVariableNames","vTEC");
        CleanOutputs.vTEC=vTEC.vTEC;
   end
end

if ~exist([DB_Dir '\Outputs'],'dir')
    mkdir([DB_Dir '\Outputs'])
end


% CREATION OF THE STATISTICS STRUCT WITH REPORTS ON ELAPSED FILES
Statistics.TimeNeeded.Total=toc(StartTicTime);
Statistics.NumOfOutOfTime=sum(Outputs_key==0);
Statistics.NumOfFiles=length(Outputs_key);


% SAVE STATISTICS AND OUTPUTS IN .MAT FORMAT IN THE OUTPUT FOLDER
save([DB_Dir '.\Outputs\' datestr(ts,'ddmmyy@hhMM') '_' datestr(te,'ddmmyy@hhMM') '_Stats.mat'],'Statistics');
save([DB_Dir '.\Outputs\' datestr(ts,'ddmmyy@hhMM') '_' datestr(te,'ddmmyy@hhMM') '_Data.mat'],'CleanOutputs');

end