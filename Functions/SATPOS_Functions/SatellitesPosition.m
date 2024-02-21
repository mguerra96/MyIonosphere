function [SATPOS,FrequencyNumber]=SatellitesPosition(t_res,dt1,DB_Dir,GNSS_Systems)

nav_files=dir([DB_Dir '\nav\*.rnx']);

dt2 = unique(dateshift(dt1, 'start', 'day'));

FrequencyNumber=struct();
SATPOS=struct();
SATPOS.GPS=[];
SATPOS.BeiDou=[];
SATPOS.Galileo=[];
SATPOS.GLONASS=[];
SATPOS.SBAS=[];

NavSBAS=[];

for iNavFile=1:length(nav_files)

    doy=str2num(nav_files(iNavFile).name(17:19));
    year=str2num(nav_files(iNavFile).name(13:16));

    if sum(dt2==datetime(doy2jd(year,doy),'ConvertFrom','juliandate'))==1

        nav=rinexread([nav_files(iNavFile).folder '\' nav_files(iNavFile).name]);
        FrequencyNumber_Temp=unique(table(nav.GLONASS.SatelliteID,nav.GLONASS.FrequencyNumber,'VariableNames',{'prn','freqn'}),'rows');
        [~,repeatedRows]=unique(FrequencyNumber_Temp.prn);
        FrequencyNumber.(datestr(datetime(doy2jd(year,doy),'ConvertFrom','juliandate'),'mmmddyyyy'))=FrequencyNumber_Temp(repeatedRows,:);
        dt=datetime(doy2jd(year,doy),'ConvertFrom','juliandate'):seconds(t_res):datetime(doy2jd(year,doy+1),'ConvertFrom','juliandate')-seconds(t_res);
        dt=intersect(dt,dt1);

        if sum(contains(GNSS_Systems,"G"))
            SATPOS.GPS=[SATPOS.GPS ; GPSSatPos(nav,dt')];
        end

        if sum(contains(GNSS_Systems,"E"))
            SATPOS.Galileo=[SATPOS.Galileo ; GALSatPos(nav,dt')];
        end

        if sum(contains(GNSS_Systems,"C"))
            SATPOS.BeiDou=[SATPOS.BeiDou ; BDSSatPos(nav,dt')];
        end

        if sum(contains(GNSS_Systems,"R"))
            SATPOS.GLONASS=[SATPOS.GLONASS ; GLOSatPos(nav,dt',t_res)];
        end

        if sum(contains(GNSS_Systems,"S"))
            NavSBAS=[NavSBAS ; nav.SBAS];
        end

    end
end

if sum(contains(GNSS_Systems,"S"))

    NavSBAS=NavSBAS(NavSBAS.PositionX<1e5,:);
    NavSBAS.PositionX=NavSBAS.PositionX*1e3;
    NavSBAS.PositionY=NavSBAS.PositionY*1e3;
    NavSBAS.PositionZ=NavSBAS.PositionZ*1e3;

    for iSatID=unique(NavSBAS.SatelliteID)'
        SatID_Nav=unique(NavSBAS(NavSBAS.SatelliteID==iSatID,:),'rows');
        if height(SatID_Nav)<10
            continue
        end
        PositionX_f=griddedInterpolant(datenum(SatID_Nav.Time),SatID_Nav.PositionX,'spline','spline');
        PositionY_f=griddedInterpolant(datenum(SatID_Nav.Time),SatID_Nav.PositionY,'spline','spline');
        PositionZ_f=griddedInterpolant(datenum(SatID_Nav.Time),SatID_Nav.PositionZ,'spline','spline');
        SatIDPos=timetable(dt1',PositionX_f(datenum(dt1))',PositionY_f(datenum(dt1))',PositionZ_f(datenum(dt1))');
        SatIDPos.SatelliteID(:)=string(['S' num2str(SatID_Nav.SatelliteID(1))]);
        SatIDPos.Properties.VariableNames={'x','y','z','prn'};
        SATPOS.SBAS=[SATPOS.SBAS ; SatIDPos];
    end
    
end

end
