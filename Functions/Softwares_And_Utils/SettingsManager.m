function [t_res,HIPP,Elevation_Cutoff,GNSS_Systems,ToNeCalibrate,ToVertical,MinArcLength]=SettingsManager(MyIonoSettings)

%function that handles the non madnatory settings and if they are not provided assigns default values

if ~isfield(MyIonoSettings,'TimeResolution')
    t_res=30;
else
    t_res=MyIonoSettings.TimeResolution;
end

if ~isfield(MyIonoSettings,'HIPP')
    HIPP=300;
else
    HIPP=MyIonoSettings.HIPP;
end

if ~isfield(MyIonoSettings,'ElevationCutoff')
    Elevation_Cutoff=20;
else
    Elevation_Cutoff=MyIonoSettings.ElevationCutoff;
end

if ~isfield(MyIonoSettings,'GNSSSystems')
    GNSS_Systems=["G","R","E","C"];
else
    GNSS_Systems=MyIonoSettings.GNSSSystems;
end

if ~isfield(MyIonoSettings,'ToNeCalibrate')
    ToNeCalibrate=0;
else
    ToNeCalibrate=MyIonoSettings.ToNeCalibrate;
end

if ~isfield(MyIonoSettings,'ToVertical')
    ToVertical=0;
else
    ToVertical=MyIonoSettings.ToVertical;
end

if ~isfield(MyIonoSettings,'MinArcLength')
    MinArcLength=3600/t_res;
else
    MinArcLength=MyIonoSettings.MinArcLength/t_res;
end


end