function [t_res,HIPP,Elevation_Cutoff,GNSS_Systems,ToCalibrate,ToVertical,MinArcLength]=SettingsManager(MyIonoSettings)

%function that handles the non madnatory settings and if they are not provided assigns default values

if ~isfield(MyIonoSettings,'TimeResolution')
    t_res=30;
else
    t_res=MyIonoSettings.TimeResolution;
end

if ~isfield(MyIonoSettings,'HIPP')
    HIPP=250;
else
    HIPP=MyIonoSettings.HIPP;
end

if ~isfield(MyIonoSettings,'ElevationCutoff')
    Elevation_Cutoff=20;
else
    Elevation_Cutoff=MyIonoSettings.ElevationCutoff;
end

if ~isfield(MyIonoSettings,'GNSSSystems')
    GNSS_Systems=["G","R","E","C","S"];
else
    GNSS_Systems=MyIonoSettings.GNSSSystems;
end

if ~isfield(MyIonoSettings,'ToCalibrate')
    ToCalibrate=0;
else
    ToCalibrate=MyIonoSettings.ToCalibrate;
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