clear
close
clc

MyIonoSettings.StartTime=datetime(2022,3,13,0,0,0);
MyIonoSettings.StopTime=datetime(2022,3,14,23,59,31);
MyIonoSettings.ElevationCutoff=15;
MyIonoSettings.TimeResolution=30;
MyIonoSettings.ToVertical=1;
MyIonoSettings.GNSSSystems=["G","R","E","C"];
MyIonoSettings.RinexDir='C:\Users\MarcoGuerra\Documents\MATLAB\RINEX_FILES';

Outputs=MyIonosphere(MyIonoSettings);