function GFLC=Compute_Doppler(obs,obs_header,FrequencyNumber,GNSS_Systems)

% THIS FUNCTION CALCULTES GEOMETRY-FREE LINEAR COMBINATION OF GNSS PAHSE MEASURMENTS
% IT CAN HANDLE RINEX V2.XX AND V3.XX AND GPS, GLONASS, GALILEO, BEIDOU AND SBAS SYSTEMS
%
% WRITTEN BY Marco Guerra

GALf1=1575.42e6; %GALILEO L1 Frequency
GALf5=1176.45e6; %GALILEO L5 Frequency
GALf7=1207.140e6; %GALILEO L7 Frequency
GALf8=1191.795e6; %GALILEO L8 Frequency

GFLC=struct();

switch floor(obs_header.FileVersion)

        % RINEX V3.xx
    case 3

        if sum(contains(GNSS_Systems,"G"))
            if isfield(obs,'GPS') && ~isempty(obs.GPS) && sum(ismember(obs.GPS.Properties.VariableNames,{'D1C','D2W'}))==2
                gps_gflc_func=@(x,y,z) GPS_GFLC(x,y,z);
                GFLC.GPS=rowfun(gps_gflc_func,obs.GPS,'InputVariables',{'D1C','D2W','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            end
        end

        if sum(contains(GNSS_Systems,"R"))
            glo_gflc_func=@(x,y,z) GLO_GFLC(x,y,z,FrequencyNumber);
            if isfield(obs,'GLONASS') && ~isempty(obs.GLONASS) && sum(ismember(obs.GLONASS.Properties.VariableNames,{'D1C','D2P'}))==2
                GFLC.GLONASS=rowfun(glo_gflc_func,obs.GLONASS,'InputVariables',{'D1C','D2P','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'GLONASS') && ~isempty(obs.GLONASS) && sum(ismember(obs.GLONASS.Properties.VariableNames,{'D1C','D2C'}))==2
                GFLC.GLONASS=rowfun(glo_gflc_func,obs.GLONASS,'InputVariables',{'D1C','D2C','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'GLONASS') && ~isempty(obs.GLONASS) && sum(ismember(obs.GLONASS.Properties.VariableNames,{'D1P','D2P'}))==2
                GFLC.GLONASS=rowfun(glo_gflc_func,obs.GLONASS,'InputVariables',{'D1P','D2P','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'GLONASS') && ~isempty(obs.GLONASS) && sum(ismember(obs.GLONASS.Properties.VariableNames,{'D1P','D2C'}))==2
                GFLC.GLONASS=rowfun(glo_gflc_func,obs.GLONASS,'InputVariables',{'D1P','D2C','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            end
        end

        if sum(contains(GNSS_Systems,"E"))
            if isfield(obs,'Galileo') && ~isempty(obs.Galileo) && sum(ismember(obs.Galileo.Properties.VariableNames,{'D1X','D5X'}))==2
                gal_gflc_func=@(x,y,z) GAL_GFLC(x,y,z,GALf1,GALf5);
                GFLC.Galileo=rowfun(gal_gflc_func,obs.Galileo,'InputVariables',{'D1X','D5X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'Galileo') && ~isempty(obs.Galileo) && sum(ismember(obs.Galileo.Properties.VariableNames,{'D1C','D5Q'}))==2
                gal_gflc_func=@(x,y,z) GAL_GFLC(x,y,z,GALf1,GALf5);
                GFLC.Galileo=rowfun(gal_gflc_func,obs.Galileo,'InputVariables',{'D1C','D5Q','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'Galileo') && ~isempty(obs.Galileo) && sum(ismember(obs.Galileo.Properties.VariableNames,{'D1X','D8X'}))==2
                gal_gflc_func=@(x,y,z) GAL_GFLC(x,y,z,GALf1,GALf8);
                GFLC.Galileo=rowfun(gal_gflc_func,obs.Galileo,'InputVariables',{'D1X','D8X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'Galileo') && ~isempty(obs.Galileo) && sum(ismember(obs.Galileo.Properties.VariableNames,{'D5I','D7I'}))==2
                gal_gflc_func=@(x,y,z) GAL_GFLC(x,y,z,GALf5,GALf7);
                GFLC.Galileo=rowfun(gal_gflc_func,obs.Galileo,'InputVariables',{'D5I','D7I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            end
        end

        if sum(contains(GNSS_Systems,"C"))
            if isfield(obs,'BeiDou') && ~isempty(obs.BeiDou)
                GFLC.BeiDou=BeiDou_GFLC_Calculator(obs,obs_header);
            end
        end

        if sum(contains(GNSS_Systems,"S"))
            if isfield(obs,'SBAS') && ~isempty(obs.SBAS) && sum(ismember(obs.SBAS.Properties.VariableNames,{'D1C','D5I'}))==2
                sbas_gflc_func=@(x,y,z) SBAS_GFLC(x,y,z);
                GFLC.SBAS=rowfun(sbas_gflc_func,obs.SBAS,'InputVariables',{'D1C','D5I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'SBAS') && ~isempty(obs.SBAS) && sum(ismember(obs.SBAS.Properties.VariableNames,{'D1C','D5Q'}))==2
                sbas_gflc_func=@(x,y,z) SBAS_GFLC(x,y,z);
                GFLC.SBAS=rowfun(sbas_gflc_func,obs.SBAS,'InputVariables',{'D1C','D5Q','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'SBAS') && ~isempty(obs.SBAS) && sum(ismember(obs.SBAS.Properties.VariableNames,{'D1C','D5X'}))==2
                sbas_gflc_func=@(x,y,z) SBAS_GFLC(x,y,z);
                GFLC.SBAS=rowfun(sbas_gflc_func,obs.SBAS,'InputVariables',{'D1C','D5X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            end
        end

        if sum(contains(GNSS_Systems,"J"))
            if isfield(obs,'QZSS') && ~isempty(obs.QZSS) && sum(ismember(obs.QZSS.Properties.VariableNames,{'D1C','D2X'}))==2
                qzss_gflc_func=@(x,y,z) QZSS_GFLC(x,y,z);
                GFLC.QZSS=rowfun(qzss_gflc_func,obs.QZSS,'InputVariables',{'D1C','D2X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'QZSS') && ~isempty(obs.QZSS) && sum(ismember(obs.QZSS.Properties.VariableNames,{'D1X','D2X'}))==2
                qzss_gflc_func=@(x,y,z) QZSS_GFLC(x,y,z);
                GFLC.QZSS=rowfun(qzss_gflc_func,obs.QZSS,'InputVariables',{'D1X','D2X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'QZSS') && ~isempty(obs.QZSS) && sum(ismember(obs.QZSS.Properties.VariableNames,{'D1C','D2L'}))==2
                qzss_gflc_func=@(x,y,z) QZSS_GFLC(x,y,z);
                GFLC.QZSS=rowfun(qzss_gflc_func,obs.QZSS,'InputVariables',{'D1C','D2L','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            elseif isfield(obs,'QZSS') && ~isempty(obs.QZSS) && sum(ismember(obs.QZSS.Properties.VariableNames,{'D1X','D2L'}))==2
                qzss_gflc_func=@(x,y,z) QZSS_GFLC(x,y,z);
                GFLC.QZSS=rowfun(qzss_gflc_func,obs.QZSS,'InputVariables',{'D1X','D2L','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
            end
        end

        %RINEX V4.xx
    case 4
        fprintf('RINEX v4.xx Not supported! \n')
    otherwise
        fprintf('Rinex Version Not recognized')
end

end

%% BeiDou GFLC Calculator

function BeiDou_GFLC=BeiDou_GFLC_Calculator(obs,obs_header)

RNXVersion=num2str(mod(obs_header.FileVersion,1));

switch string(RNXVersion)

    case {"0.01","0.02"}
        fL1=1561.098e6;
        fL6=1268.52e6;
        fL7=1207.14e6;

        if sum(ismember(obs.BeiDou.Properties.VariableNames,{'D1I','D6I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL1,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D1I','D6I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D1X','D6X'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL1,fL7);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D1X','D6X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D1I','D7I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL1,fL7);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D1I','D7I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2I','D6I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL1,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D6I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2I','D7I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL1,fL7);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D7I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        else
            BeiDou_GFLC=[];
        end


    case {"0.03","0.04","0.05"}
        fL2=1561.098e6;
        fL6=1268.52e6;
        fL7=1207.140e6;

        if sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2I','D6I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D6I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2X','D6X'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2X','D6X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2I','D6X'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D6X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2X','D6I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL6);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D6I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2I','D7I'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL7);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2I','D7I','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        elseif sum(ismember(obs.BeiDou.Properties.VariableNames,{'D2X','D7X'}))==2
            bds_gflc_func=@(x,y,z) BDS_GFLC(x,y,z,fL2,fL7);
            BeiDou_GFLC=rowfun(bds_gflc_func,obs.BeiDou,'InputVariables',{'D2X','D7X','SatelliteID'},'OutputVariableNames',{'gflc','prn'});
        else
            BeiDou_GFLC=[];
        end

end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% GPS GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC , prn]=GPS_GFLC(D1,D2,prn)

c = 299792500.0;
L1 = 1575.42e6;
L2 =  1227.60e6;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['G' num2str(prn,'%.02d')]);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% GLONASS GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC,prn]=GLO_GFLC(D1,D2,prn,FrequencyNumber)

if ~isnumeric(prn) %this accounts rinex 2 having SatelliteID in char format instead of int
    prn=my_str2num(prn);
end

FNum_glonass=FrequencyNumber(FrequencyNumber.prn==prn,:).freqn;

if isempty(FNum_glonass)
    FNum_glonass=nan;
end

c = 299792500.0;
L1 = (1602 + FNum_glonass * 0.5625)*1e6;
L2 = (1246 + FNum_glonass * 0.4375)*1e6;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['R' num2str(prn,'%.02d')]);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% GALILEO GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC , prn]=GAL_GFLC(D1,D2,prn,freq1,freq2)

c = 299792500.0;
L1 = freq1;
L2 =  freq2;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['E' num2str(prn,'%.02d')]);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% BEIDOU GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC,prn]=BDS_GFLC(D1,D2,prn,freq1,freq2)

c = 299792500.0;
L1 = freq1;
L2 =  freq2;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['C' num2str(prn,'%.02d')]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% SBAS GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC , prn]=SBAS_GFLC(D1,D2,prn)

c = 299792500.0;
L1 = 1575.42e6;
L2 =  1176.45e6;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['S' num2str(prn,'%.02d')]);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% QZSS GFLC FUNCTION %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GFLC , prn]=QZSS_GFLC(D1,D2,prn)

c = 299792500.0;
L1 = 1575.42e6;
L2 =  1227.60e6;
lambdaL1 = c / L1;
lambdaL2 = c / L2;

GFLC=1/40.3*(L1^2*L2^2)/(L1^2-L2^2)*(lambdaL1*D1-lambdaL2*D2)/1e16;

prn=string(['J' num2str(prn,'%.02d')]);

end