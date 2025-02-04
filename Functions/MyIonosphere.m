function [Outputs , Statistics]=MyIonosphere(MyIonoSettings)

% FUNCTION THAT READS RINEX OBSERVATIONAL FILES (v2.xx and v3.xx) AND CALCULATES GGFLC AND IPPS
% THIS FUNCTION CAN HANDLE GPS, GLONASS, GALILEO, BEIDOU AND SBAS SATELLITES
%
% MANDATORY INPTUS ARE:
% StartTime         (datetime)              ---> start_time in datetime format
% StopTime          (datetime)              ---> stop_time in datetime format
% RinexDir          (system path)           ---> Path to directory were obs files are stored
%
% NON MANDATORY INPUTS ARE:
% TimeResolution    (seconds)               ---> Time resolution of rinex observational files (DEFAULT: 30s)
% HIPP              (km)                    ---> Height of the ionospheric layer for the calculation of the iono piercing point (DEFAULT: 300km)
% ElevationCutoff   (degress)               ---> Minimum acceptable elevation, every data point with elevation lower than cutoff is not included (DEFAULT: 20°)
% GNSSSystems       (list of systems)       ---> List of GNSS constellations to consider (DEFAULT: GREC)
% ToNeCalibrate     (1 or 0)                ---> If true calibration bias is estimated through NeQuick (DEFAULT: 0)
% MinArcLength      (seconds)               ---> If GNSS TEC arc is shorter than MinArcLength the arc is discarded (DEFAULT: 3600s)
% ToVertical        (1 or 0)                ---> If true the arcs are verticalized (DEFAULT: 0)
% Observable        ('Phase' or 'Doppler')  ---> Which observables to use, phase or doppler (DEFAULT: Phase)
%
% Written by Marco Guerra

warning off

% SETTINGS MANAGER

if isfield(MyIonoSettings,'StartTime') && isfield(MyIonoSettings,'StopTime')
    ts=MyIonoSettings.StartTime;
    te=MyIonoSettings.StopTime;
else
    fprintf('ERROR: No valid start and end time provided!')
    return
end

if isfield(MyIonoSettings,'RinexDir')
    DB_Dir=MyIonoSettings.RinexDir;
else
    fprintf('ERROR: No RINEX_FILES directory in input settings!')
    return
end

[t_res,HIPP,Elevation_Cutoff,GNSS_Systems,ToNeCalibrate,ToGGCalibrate,ToVertical,MinArcLength,Observable]=SettingsManager(MyIonoSettings);

NumOfThreads=10;

StartTicTime=tic;
StepTicTime=tic;
Statistics=struct();
Statistics.TimeNeeded=struct();

dt=ts:seconds(t_res):te;               %initalize times for SATPOS calculation
doys=unique(floor(date2doy(datenum(dt))));
yy=year(ts);
yy_string=char(string(yy));
yy_string=string(yy_string(3:4));

% DOWLOADING NEEDED BRDC FILES AND CALCULATING SATELLITE POSITIONS

for doy=doys
    BRDC_Grabber(doy,yy,DB_Dir);
end

fprintf('CALCULATING SATELLITE POSITION...\n')
[SATPOS , FrequencyNumber]=SatellitesPosition(t_res,dt,DB_Dir,GNSS_Systems);        %calculates satellite position for given systems and times (dt)
Statistics.TimeNeeded.SATPOS=toc(StepTicTime);
StepTicTime=tic;


% EXTRACTING OBS FILES IF THEY ARE HATANAKA COMPRESSED OR GZIPPED

if t_res==30
    Unzip_And_DeHata(DB_Dir)        % if obs files are zipped this function unzips them
    NumOfThreads=8;
end

% READING RINEX OBS FILES AND MERGING OBSERVATIONS WITH SATELLITE POSITIONS

obs_files=[dir([DB_Dir '/obs/*.rnx']) ; dir([DB_Dir '/obs/*.*o'])];

if isempty(obs_files)
    fprintf('ERROR: No observational files for given time period\n')
    return
end

Outputs=cell(size(obs_files));
Outputs_key=zeros(size(obs_files));

Station_Coord=table(string(zeros(size(obs_files))),zeros(size(obs_files)),zeros(size(obs_files)));
Station_Coord.Properties.VariableNames={'StatName','StaLon','StaMoDip'};

fprintf('READING RINEX FILES...\n')

WaitMessage = parfor_wait(length(obs_files), 'Waitbar', true);

parfor (fileIdx=1:size(obs_files,1),NumOfThreads)
% for fileIdx=1:size(obs_files,1)

    obs_file=obs_files(fileIdx);

    if  ~contains(obs_file.name,string(doys)) || ~contains(obs_file.name,yy_string)
        continue
    end

    try
        [obs, obs_header]=MyRinexRead(obs_file); %read obs files and manage possible errors
    catch ME    %catch reading error and save error type along with faulty rinex
        obs=[];
        obs_header=[];
        fprintf(['Error loading obs file: ' obs_file.name '\n']);
        Outputs{fileIdx}={ME obs_file.name};
        Outputs_key(fileIdx,1)=-1;
        if ~exist([DB_Dir '/Errors/' datestr(ts,'yy_mm_dd')],'dir')
            mkdir([DB_Dir '/Errors/' datestr(ts,'yy_mm_dd')])
        end
        try
            movefile([obs_file.folder '/' obs_file.name],[DB_Dir  '/Errors/' datestr(ts,'yy_mm_dd') '/' obs_file.name],'f');
        end
    end


    if ~isempty(obs)
        try

            if Observable=="Phase"
                Outputs{fileIdx}=MergeObsSatPos(SATPOS,Compute_GFLC(obs,obs_header,FrequencyNumber.(datestr(obs_header.FirstObsTime,'mmmddyyyy')),GNSS_Systems),obs_header,HIPP); %merge satpos and GFLC data and calculates IPPs
            elseif Observable=="Doppler"
                Outputs{fileIdx}=MergeObsSatPos(SATPOS,Compute_Doppler(obs,obs_header,FrequencyNumber.(datestr(obs_header.FirstObsTime,'mmmddyyyy')),GNSS_Systems),obs_header,HIPP); %merge satpos and GFLC data and calculates IPPs
            else
                fprintf('ERROR: Observable field not recognized (Has to be Phase or Doppler)\n')
            end

            Outputs{fileIdx}.stat(:)=string(obs_file.name(1:4));
            Outputs_key(fileIdx,1)=1;
            Station_lla=ecef2lla(obs_header.ApproxPosition);
            Station_Coord(fileIdx,:)=table(string(obs_header.MarkerName(1:4)),Station_lla(2),Calculate_MoDip(Station_lla(1),Station_lla(2),dt(1),HIPP));

        catch ME     %catch error in calculating the GFLC and save error type along with faulty rinex
            fprintf(['Error computing GFLC/RTEC for file: ' obs_file.name '\n']);
            Outputs{fileIdx}={ME obs_file.name};
            Outputs_key(fileIdx,1)=-1;
            if ~exist([DB_Dir '/Errors/' datestr(ts,'yy_mm_dd')],'dir')
                mkdir([DB_Dir '/Errors/' datestr(ts,'yy_mm_dd')])
            end
            try
                movefile([obs_file.folder '/' obs_file.name],[DB_Dir '/Errors/'  datestr(ts,'yy_mm_dd') '/' obs_file.name],'f');
            end
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

clearvars Outputs

if isempty(CleanOutputs)
    fprintf('ERROR: No valid observational files provided\n')
    Outputs=[];
    return
end


% CREATION OF THE DATAFRAME WITH ALL THE OBSERVATIONAL ARCS

fprintf('CREATING DATAFRAME WITH OBSERVATIONAL ARCS...\n')
CleanOutputs=vertcat(CleanOutputs{:});  %merge all data into one single table to easy further computations
CleanOutputs.ArcID=string([char(CleanOutputs.stat) repmat('_',height(CleanOutputs),1) char(CleanOutputs.prn)]);  %create 1 unique ID for each receiver-satellite pair
CleanOutputs=CleanOutputs(CleanOutputs.ele>=Elevation_Cutoff,:);    %remove data that are at elevations lower than the treshold
CleanOutputs=CleanOutputs(sum(isstrprop(char(CleanOutputs.stat),'alpha') | isstrprop(char(CleanOutputs.stat),'digit'),2)==4,:);

Statistics.TimeNeeded.ToTable=toc(StepTicTime);
StepTicTime=tic;

% CREATION OF ID OF SINGLE ARCS TO ALLOW OPEARTION ON ARCS

fprintf('CREATING ARC UNIQUE IDENTIFIER...\n')
CleanOutputs=sortrows(timetable2table(CleanOutputs),{'ArcID','Time'});
Arc_Splitter_Func=@(x) Arc_Splitter(x,t_res);   %initialize functions that splits arcs when a data gap (larger than treshold) is found and assigns unique ID to each continuos arc
ArcIDNum=sortrows(rowfun(Arc_Splitter_Func,CleanOutputs,"GroupingVariables","ArcID","InputVariables","Time","OutputVariableNames","ArcIDNum"),'ArcID');
CleanOutputs.ArcID=string([char(CleanOutputs.ArcID) repmat('_',height(CleanOutputs),1) char(ArcIDNum.ArcIDNum)]);
CleanOutputs=removevars(CleanOutputs,{'stat','prn'});
CleanOutputs.Properties.VariableNames={'Time','GFLC','Lat','Lon','Azi','Ele','ArcID'};
CleanOutputs=sortrows(CleanOutputs,{'ArcID','Time'});

Statistics.TimeNeeded.ArcID=toc(StepTicTime);
StepTicTime=tic;

% DROP ARCS THAT ARE TOO SHORT

fprintf('DROPPING ARCS THAT ARE TOO SHORT...\n')
CleanOutputs.ArcID=categorical(CleanOutputs.ArcID);
IDCounts=groupcounts(CleanOutputs,'ArcID');
Arc2Delete=IDCounts(IDCounts.GroupCount<MinArcLength,:);
CleanOutputs=CleanOutputs(~ismember(CleanOutputs.ArcID,Arc2Delete.ArcID),:);

Statistics.TimeNeeded.CleanShortArcs=toc(StepTicTime);
StepTicTime=tic;

% CORRECTION OF PHASE JUMPS TO AVOID DETRENDING OUTLIERS /// INTEGRATION OF ROT FOR DOPPLER MEASUREMENTS

if Observable=="Phase"
    fprintf('CORRECTION OF PHASE JUMPS...\n')
    PhaseJumpsCorrector_f=@(x,t) PhaseJumpsCorrector(x,t,5);    %initialize the function that checks if phase jumps are present in GFLC arcs
    GFLC_Corrected=rowfun(PhaseJumpsCorrector_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Time'},"OutputVariableNames",{'GFLC','Time'});
    GFLC_Corrected=sortrows(GFLC_Corrected,{'ArcID','Time'});
    CleanOutputs.GFLC=GFLC_Corrected.GFLC;
elseif Observable=="Doppler"
    fprintf('Integration of Doppler-derived ROT')
    MyCumSum_f=@(x,t) MyCumSum(x,t);
    GFLC_Integrated=rowfun(MyCumSum_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Time'},"OutputVariableNames",{'GFLC','Time'});
    GFLC_Integrated=sortrows(GFLC_Integrated,{'ArcID','Time'});
    CleanOutputs.GFLC=GFLC_Integrated.GFLC;
end

Statistics.TimeNeeded.PhaseJumps=toc(StepTicTime);
StepTicTime=tic;


% CALIBRATION WITH NeQuick2 TO REDUCE DETRENING ERRORS ON AMPLITUDE

Calibrated=false;

if ToNeCalibrate
    fprintf('CALIBRATION WITH NeQuick2...\n')
    NeQuick_Calibrator_Func=@(stec,latitude,longitude,azimuth,elevation,time) NeQuick_Calibrator(stec,latitude,longitude,azimuth,elevation,time);   %initialize functions that estimates the stec values with NeQuick2
    sTEC=rowfun(NeQuick_Calibrator_Func,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Lat','Lon','Azi','Ele','Time'},"OutputVariableNames","sTEC");
    CleanOutputs.sTEC=sTEC.sTEC;
    CleanOutputs=CleanOutputs(~isnan(CleanOutputs.sTEC),:);
    Calibrated=true;

    Statistics.TimeNeeded.NeQuickCalibration=toc(StepTicTime);
    StepTicTime=tic;
end


%CALIBRARTION FROM GFLC TO STEC USING GG TECHNIQUE

if ToGGCalibrate
    fprintf('CALIBRATING GEOM_FREE_LIN_COMB...\n')

    [offset, LoUA] = GG_Calibration(CleanOutputs,Station_Coord,30,2,HIPP);

    for i =1:size(CleanOutputs,1)
        index_arcID=find(LoUA==string(CleanOutputs(i,'ArcID').ArcID));
        CleanOutputs.sTEC(i)=CleanOutputs.GFLC(i)-offset(index_arcID);
    end
    Calibrated=true;
    Statistics.TimeNeeded.GGCalibration=toc(StepTicTime);
    StepTicTime=tic;
end

% VERTICALIZATION OF TEC ARCS

if ToVertical
    fprintf('VERTICALIZATION...\n')
    vert_f=@(vtec,ele) Verticalization(vtec,ele,HIPP);      %initialize functions that verticalizes the observational arcs

    if Calibrated
        vTEC=rowfun(vert_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'sTEC','Ele'},"OutputVariableNames","vTEC");
        CleanOutputs.vTEC=vTEC.vTEC;    %if tec was calibrated with NeQuick sTEC is verticalized
        CleanOutputs.GFLC=[]; %Delete useless data to save space
        CleanOutputs.sTEC=[]; %Delete useless data to save space

        Statistics.TimeNeeded.Verticalization=toc(StepTicTime);
    else
        vTEC=rowfun(vert_f,CleanOutputs,"GroupingVariables","ArcID","InputVariables",{'GFLC','Ele'},"OutputVariableNames","vTEC");
        CleanOutputs.vTEC=vTEC.vTEC;    % if TEC was not calibrated the GFLC at 0 mean is verticalized (the 0 mean should reduce verticalization errors)
        CleanOutputs.GFLC=[]; %Delete useless data to save space

        Statistics.TimeNeeded.Verticalization=toc(StepTicTime);
    end
end

if ~exist([DB_Dir '/Outputs'],'dir')
    mkdir([DB_Dir '/Outputs'])
end

% CREATION OF THE STATISTICS STRUCT WITH REPORTS ON ELAPSED FILES
Statistics.TimeNeeded.Total=toc(StartTicTime);
Statistics.NumOfOutOfTime=sum(Outputs_key==0);
Statistics.NumOfFiles=length(Outputs_key);

Outputs=CleanOutputs;
clear CleanOutputs

fprintf('SAVING OUTPUTS...\n')

% SAVE STATISTICS AND OUTPUTS IN .MAT FORMAT IN THE OUTPUT FOLDER
save([DB_Dir './Outputs/' datestr(ts,'yymmdd@hhMM') '_' datestr(te,'yymmdd@hhMM') '_Stats.mat'],'Statistics');
save([DB_Dir './Outputs/' datestr(ts,'yymmdd@hhMM') '_' datestr(te,'yymmdd@hhMM') '_Data.mat'],'Outputs','-v7.3');

end