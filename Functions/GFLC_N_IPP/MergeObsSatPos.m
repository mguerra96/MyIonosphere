function output=MergeObsSatPos(SATPOS,GFLC,obs_header,HIPP)

% Merge GFLC and SATPOS struct and calulcate IPPs for every constellation requested

Constellations=fieldnames(GFLC);

output=[];

for Constellation=Constellations'
    if ~isempty(GFLC.(Constellation{1})) && ~isempty(SATPOS.(Constellation{1}))

        SATPOS_GFLC=innerjoin(GFLC.(Constellation{1}),SATPOS.(Constellation{1}),'Keys',{'Time','prn'});

        geometry_f= @(x,y,z) Calculate_IPP(obs_header.ApproxPosition,x,y,z,HIPP);   %initiale function that calulcated IPP location for given station
        rowfun_output=rowfun(geometry_f,SATPOS_GFLC,'InputVariables',{'x','y','z'},'OutputVariableNames',{'lat','lon','azi','ele'});

        SATPOS_GFLC.lat=rowfun_output.lat;
        SATPOS_GFLC.lon=rowfun_output.lon;
        SATPOS_GFLC.azi=rowfun_output.azi;
        SATPOS_GFLC.ele=rowfun_output.ele;
        SATPOS_GFLC(:,[3 4 5])=[];
        output=[output; SATPOS_GFLC];

    end
    
end

output=output(~isnan(output.gflc),:);

end